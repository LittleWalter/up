# ╻ ╻┏━┓   ╻ ╻╻┏━┓╺┳╸┏━┓┏━┓╻ ╻ ┏┓ ┏━┓┏━┓╻ ╻
# ┃ ┃┣━┛   ┣━┫┃┗━┓ ┃ ┃ ┃┣┳┛┗┳┛ ┣┻┓┣━┫┗━┓┣━┫
# ┗━┛╹  ╺━╸╹ ╹╹┗━┛ ╹ ┗━┛╹┗╸ ╹ ╹┗━┛╹ ╹┗━┛╹ ╹
# `up` path history function definitions

# Prints the history logging status
up::print_history_status() {
	[[ "$HIST_ENABLED" == true ]] && up::print_msg "history enabled at: $LOG_FILE (max size $LOG_SIZE)" && return 0
	up::print_msg "history disabled; set \`export _UP_ENABLE_HIST=true\` in shell config"
}

# Add a line to the history log w/ time and date: $1=<path to log>
up::log_history() {
	local -r log_entry="$1"
	local -r timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
	echo "$timestamp $log_entry" >> "$LOG_FILE"
	# Trim log file
	tail -n $LOG_SIZE "$LOG_FILE" > "$LOG_FILE.tmp" && mv "$LOG_FILE.tmp" "$LOG_FILE"
}

# Checks to see if path changed before adding line to history
# $1=<prejump_path>
up::validate_and_log_history() {
	[[ "$HIST_ENABLED" != true ]] && return 0

	local -r prejump_path="$1"
	local -r log_entry="$PWD"

	if [[ "$log_entry" != "$prejump_path" ]]; then
		# WARN: Potential race conditions for log file on multiple shell instances
		# IDEA: Code is a rudimentary locking simulation, try `flock` and `lockf`?
		# Might be overkill for non-critical path history logging
		local -r lock_file="/tmp/up_history.lock"
		local -r retries=10 # Maximum retries to lock
		local -r delay=0.1  # Delay in seconds
		for ((i=1; i<=retries; i++)); do
			# Acquire the lock using a unique identifier (e.g., PID)
			if echo "$$" >"$lock_file" 2>/dev/null; then
				# Perform logging
				up::log_history "$log_entry"
				# Release lock
				rm -f "$lock_file"
				return 0
			else
				sleep "$delay"
			fi
		done
		# Failed to acquire lock; report failure
		up::print_msg "failed to acquire history file lock after $retries attempts"
		return "$ERR_ACCESS"
	else
		return "$ERR_NO_CHANGE"
	fi
}

# Removes missing/removed paths from history file
up::prune_history() {
	[[ ! -f "$LOG_FILE" ]] && up::print_msg "no history file found to prune..." && return 0

	local -r lock_file="/tmp/up_history.lock"
	local -r temp_file="${LOG_FILE}.tmp"
	local -r original_count=$(up::history_count)

	[[ "$original_count" -eq 0 ]] && up::print_msg "no history entries to prune, file empty..." && return 0

	# Try to acquire the lock
	local -r max_retries=10  # Limit retries to 100 (10 seconds with 0.1s sleeps)
	local attempts=0
	while ! (echo $$ > "$lock_file" 2>/dev/null); do
		sleep 0.1 # Wait for the lock to be released
		((attempts++))
		if [[ $attempts -ge $max_retries ]]; then
			up::print_msg "failed to acquire lock after $max_retries attempts"
			return "$ERR_ACCESS"
		fi

		# Check for stale lock (optional)
		lock_pid=$(cat "$lock_file" 2>/dev/null || echo "")
		if [[ -n "$lock_pid" ]] && ! ps -p "$lock_pid" > /dev/null 2>&1; then
			up::print_msg "removing stale lock file (PID $lock_pid not running)"
			rm -f "$lock_file"
		fi
	done

	# Perform pruning only if lock acquired
	{
		# Filter out invalid paths, preserve timestamps
		awk '
		{
			path = substr($0, index($0, $3)) # Extract the path (skip timestamp)
			gsub(/^ +| +$/, "", path)        # Trim whitespace
			if (system("[ -d \"" path "\" ]") == 0) print $0
		}' "$LOG_FILE" > "$temp_file"

		# Replace the log file with the pruned version
		mv "$temp_file" "$LOG_FILE"
	} || { up::print_msg "failed to prune the history file"; return "$ERR_ACCESS"; }

	rm -f "$lock_file" # Release lock

	# Print summary
	local -r new_count=$(up::history_count)
	local -r count_diff=$((original_count - new_count))
	if [[ "$count_diff" -eq 0 ]]; then
		up::print_msg "nothing pruned: all ${DIR_CHANGE_STYLE}$original_count${RESET} entries are valid paths (max: $LOG_SIZE)"
	else
		up::print_msg "pruned history: removed $count_diff invalid paths (${DIR_CHANGE_STYLE}$new_count${RESET} remaining, max: $LOG_SIZE)"
	fi
}

# Clear history log file
up::clear_history() {
	local -r count=$(up::history_count)
	if [[ -f "$LOG_FILE" ]] && [[ "$count" -gt 0 ]]; then
		: > "$LOG_FILE" # Truncate to clear
		if [[ "$(up::history_count)" -eq 0 ]]; then
			up::print_msg "history file cleared: $LOG_FILE"
		else
			up::print_msg "history file not cleared!"
		fi
	else
		up::print_msg "no history to clear..."
	fi
	[[ "$HIST_ENABLED" == false ]] && up::print_history_status
}

# Number of entries (lines) in the history log file
up::history_count() {
	#[[ -f "$LOG_FILE" ]] && echo "$(wc -l < "$LOG_FILE")" && return 0
	[[ -f "$LOG_FILE" ]] && wc -l < "$LOG_FILE" | xargs && return 0
	echo "0" # history file doesn't exist
}

# Print current size of history log w/ horizonal bar, percentage, and count/LOG_SIZE
up::print_history_size() {
	local -r current=$(up::history_count)
	local -r max=${LOG_SIZE}
	local -r scale=20
	local -r percent=$((current * scale / max))
	# Construct the bar
	local -r completed_bar="$(printf '%*s' "$percent" | tr ' ' '=')"
	local -r incomplete_bar="$(printf '%*s' "$((scale - percent))" | tr ' ' '.')"
	local -r bar="[${DIR_CHANGE_STYLE}$completed_bar${RESET}$incomplete_bar]"

	up::print_msg "history size: ${bar} $((current * 100 / max))% (${DIR_CHANGE_STYLE}${current}${RESET}/${max})"
	[[ "$HIST_ENABLED" == false ]] && up::print_history_status
}

# Print the history log file w/ pagination
up::show_history() {
	local -r count=$(up::history_count)
	if [ "$count" -eq 0 ]; then
		up::print_msg "no history entries..."
		[[ "$HIST_ENABLED" == false ]] && up::print_history_status
	elif [[ -f "$LOG_FILE" ]]; then
		# Display a numbered list of history entries in reverse order
		local -r base_history_command='up::print_help_label "PATH HISTORY"; nl -b a <(tac "$LOG_FILE")'

		# Array of paginators (commands w/o options)
		local paginators=("bat" "less" "most" "more")

		for paginator in "${paginators[@]}"; do
			if up::is_command_available "$paginator"; then
				case "$paginator" in
					bat)
						eval "$base_history_command" | bat --style="plain"
						;;
					*) # paginators w/o options
						eval "$base_history_command" | "$paginator"
						;;
				esac
				[[ "$HIST_ENABLED" == false ]] && { echo ""; up::print_history_status; }
				return
			fi
		done

		# Fallback: No paginator available
		eval "$base_history_command"
		[[ "$HIST_ENABLED" == false ]] && { echo ""; up::print_history_status; }
	else
		up::print_msg "no history file available..."
	fi
}

# History log file is in chronological order (oldest to newest), so we
# must get the reverse index since `up::jump_from_history` outputs
# bottom up (i.e., most recent path)
# $1=<index>
up::reverse_history_index() {
	local index="$1"
	index=$(up::remove_leading_zeros "$index")
	local -r count=$(up::history_count)
	echo $((count - index + 1))
}

# Jump to a history path in LOG_FILE: $1=<history line number>
up::jump_from_history() {
	local -r index="$1"
	local -r prejump_path="$PWD"

	# Validate index input as integer value
	if ! [[ "$index" =~ ^[0-9]+$ ]]; then
		up::print_msg "not a valid history index: ${ERR_STYLE}'$index'${RESET}"
		return "$ERR_BAD_ARG"
	fi

	# Get the total number of lines in the log file
	local -r total_lines=$(up::history_count)

	# Check if the index is within the valid range
	if (( index < 1 || index > total_lines )); then
		up::print_msg "history index is out of range: ${ERR_STYLE}$index${RESET}"
		return $ERR_BAD_ARG
	fi

	local -r reversed_index=$(up::reverse_history_index "$index")

	# Extract the directory path from the history file
	local dir="$(sed "${reversed_index}q;d" "$LOG_FILE" | awk '{print $3 " " $4 " " $5}')"

	# Ensure that only valid directory paths are handled
	dir=$(echo "$dir" | sed -e 's/^ *//;s/ *$//') # Trim extra whitespace

	if [[ "$dir" == "$PWD" ]]; then
		up::print_msg "already in: ${PWD_STYLE}$dir${RESET}"
		return $ERR_NO_CHANGE
	# Check if the directory exists, then jump to it
	elif [[ -d "$dir" ]]; then
		cd "$dir" || up::print_msg "failed to jump to ${ERR_STYLE}$dir${RESET}"
		up::validate_and_log_history "$prejump_path"
		if [[ "$verbose_mode" == true ]]; then
			local -r msg="jumped to ${DIR_CHANGE_STYLE}index $index${RESET} in history (line $reversed_index)"
			up::print_verbose VERBOSE_DEFAULT "$prejump_path" "$msg"
		fi
	else
		up::print_msg "path does not exist: ${ERR_STYLE}$dir${RESET}"
		return "$ERR_BAD_ARG"
	fi
}

# Filter existing paths in the history log using fzf and change into the selected directory
up::filter_history_with_fzf() {
	local -r prejump_path="$PWD"

	[[ "$HIST_ENABLED" == false ]] && up::print_history_status

	if ! up::is_command_available "fzf"; then
		up::print_msg "\`fzf\` command not found: check installation of fuzzy finder"
		return "$ERR_ACCESS"
	elif [[ "$(up::history_count)" -eq 0 ]]; then
		up::print_msg "no history entries..."
		return 0
	fi

	if [[ -f "$LOG_FILE" ]]; then
		# Filter out missing paths from the history file
		local valid_paths=$(tac "$LOG_FILE" | awk '{$1=$2=""; print substr($0, 3)}' | while read -r path; do
			[[ -d "$path" ]] && echo "$path"
		done)

		# Check if there are valid paths to filter
		if [[ -z "$valid_paths" ]]; then
			up::print_msg "paths in history file no longer exist..."
			return 0
		fi

		# Run fzf with valid paths
		local selected_path=$(echo "$valid_paths" | fzf "${FZF_HISTOPTS[@]}")

		if [[ "$selected_path" == "$PWD" ]]; then
			up::print_msg "fzf: already in: ${PWD_STYLE}$selected_path${RESET}"
			return "$ERR_NO_CHANGE"
		elif [[ -n "$selected_path" ]]; then
			if [[ -d "$selected_path" ]]; then
				cd "$selected_path" || up::print_msg "fzf: failed to change directory to: ${ERR_STYLE}$selected_path${RESET}"
				if [[ "$verbose_mode" == true ]]; then
					local -r msg="fzf: changed path in history"
					up::print_verbose VERBOSE_DEFAULT "$prejump_path" "$msg"
				fi
				up::validate_and_log_history "$prejump_path"
			else
				up::print_msg "fzf: not a valid directory: ${ERR_STYLE}$selected_path${RESET}"
				return "$ERR_BAD_ARG"
			fi
		else
			up::print_msg "fzf: no path selected in history"
		fi
	else
		up::print_msg "fzf: no history file available to filter"
		return "$ERR_BAD_ARG"
	fi
}
