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
		awk -v verbose="$verbose_mode" '
		BEGIN { header_printed = 0 } # Flag to track if header is printed
		{
			path = substr($0, index($0, $3)) # Extract the path (skip timestamp)
			gsub(/^ +| +$/, "", path)        # Trim whitespace
			if (system("[ -d \"" path "\" ]") == 0) {
				print $0 >> "'"$temp_file"'"   # Save valid paths to temp_file
			} else if (verbose == "true") {
				if (header_printed == 0) {
					print "History Line: Invalid Path";
					header_printed = 1; # Set flag to prevent duplicate header
				}
				print NR ": " path # Print line number and invalid path
			}
	}' "$LOG_FILE"

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
		[[ "$verbose_mode" == true ]] && echo "" # Whitespace to separate removed paths list
		up::print_msg "pruned history: removed ${ERR_STYLE}$count_diff invalid paths${RESET} (${DIR_CHANGE_STYLE}$new_count remaining${RESET}, max: $LOG_SIZE)"
	fi
}

# Clear history log file with optional timeframe and lockfile mechanism: $1=<integer>(min|h|d|m)
up::clear_history() {
	local timeframe="$1" # Accepts timeframe (e.g., "1h", "2d", "15min")
	[[ ! -f "$LOG_FILE" ]] && up::print_msg "No history file available..." && return 0
	local -r original_count=$(up::history_count)
	local new_count
	local diff_count

	# Attempt to acquire the lock
	for ((i=1; i<=retries; i++)); do
		if (set -o noclobber; echo "$$" > "$lockfile") 2>/dev/null; then
			trap 'rm -f "$lockfile"' EXIT # Ensure lockfile is removed on exit
			break
		else
		# Check if the process holding the lock is still running
			if [[ -f "$lockfile" ]]; then
				lock_pid=$(cat "$lockfile")
				if ! ps -p "$lock_pid" > /dev/null 2>&1; then
					up::print_msg "stale lockfile detected, cleaning it up..."
					rm -f "$lockfile"
					continue
				fi
			fi
		fi

		if ((i == retries)); then
			up::print_msg "failed to acquire lock after $retries attempts."
			return "$ERR_ACCESS"
		fi
		sleep "$delay" # Wait before retrying
	done

	# If no timeframe is provided, delete all entries
	if [[ -z "$timeframe" ]] && [[ "$original_count" -gt 0 ]]; then
		: > "$LOG_FILE" # Truncate the log file
		new_count=$(up::history_count)
		diff_count=$((original_count - new_count))
		up::print_msg "history file cleared ${DIR_CHANGE_STYLE}$diff_count entries${RESET}: $LOG_FILE."
		return 0
	elif [[ "$original_count" -eq 0 ]]; then
		up::print_msg "no history entries to clear..."
			return 0
	fi

	local lockfile="/tmp/up_history.lock" # Lockfile location
	local retries=10   # Maximum retries for acquiring the lock
	local delay=0.1    # Delay between retries

	# Convert timeframe to seconds
	local seconds=0
	case "$timeframe" in
		*min) seconds=$(( ${timeframe%min} * 60 )) ;;  # Minutes
		*h) seconds=$(( ${timeframe%h} * 3600 )) ;;    # Hours
		*d) seconds=$(( ${timeframe%d} * 86400 )) ;;   # Days
		*m) seconds=$(( ${timeframe%m} * 2592000 )) ;; # Months (~30 days/month)
		*) up::print_msg "Invalid timeframe format: use '15min', '1h', '2d', '6m', etc." && return "$ERR_BAD_ARG" ;;
	esac

	# Current time and cutoff time (in UNIX seconds)
	local current_time=$(date +%s)
	local cutoff_time=$((current_time - seconds))

	# Use Perl to filter and retain entries newer than the cutoff time
	perl -e '
		use strict;
		use warnings;
		use Time::Local;

		my $cutoff = $ARGV[0]; # Pass cutoff time as an argument
		while (<STDIN>) {
			chomp;
			if (/^(\d{4}-\d{2}-\d{2}) (\d{2}:\d{2}:\d{2}) (.+)$/) {
				my $timestamp = "$1 $2";

				# Parse timestamp into epoch time
				if ($timestamp =~ /(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2})/) {
					my ($year, $mon, $mday, $hour, $min, $sec) = ($1, $2, $3, $4, $5, $6);
					my $epoch = timelocal($sec, $min, $hour, $mday, $mon - 1, $year);

					if ($epoch >= $cutoff) { # Keep entry
						print "$_\n";
					}
				}
			}
		}
	' "$cutoff_time" < "$LOG_FILE" > "${LOG_FILE}.tmp"

	# Replace the original log file with the filtered entries
	mv "${LOG_FILE}.tmp" "$LOG_FILE"

	# Print summary
	new_count=$(up::history_count)
	count_diff=$((original_count - new_count))
	if [[ "$count_diff" -eq 0 ]]; then
		up::print_msg "did not clear any history entries older than $timeframe..."
	else
		up::print_msg "cleared ${DIR_CHANGE_STYLE}$count_diff history entries${RESET} older than $timeframe: $LOG_FILE"
	fi
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

# Print the paths visited by frequency w/ pagination
up::print_paths_by_frequency() {
	if [[ -f "$LOG_FILE" ]] && [[ "$(up::history_count)" -ne 0 ]]; then
		local -r most_freq_command="up::print_help_label 'PATHS BY FREQUENCY'; awk '{print substr(\$0, index(\$0, \$3))}' $LOG_FILE | sort | uniq -c | sort -nr"
		up::run_with_pagination "$most_freq_command"
	elif [[ "$(up::history_count)" -eq 0 ]]; then
		up::print_msg "history file is empty..."
	else
		up::print_msg "no history file available..."
	fi
}

# Runs an arbitrary command with pagination: $1=<command>
up::run_with_pagination() {
	local -r base_command="$1"

	# Array of paginators (commands w/o options)
	local -r paginators=("bat" "less" "most" "more")

	for paginator in "${paginators[@]}"; do
		if up::is_command_available "$paginator"; then
			case "$paginator" in
				bat)
					eval "$base_command" | bat --style="plain"
					;;
				*) # paginators w/o options
					eval "$base_command" | "$paginator"
					;;
			esac
			[[ "$HIST_ENABLED" == false ]] && { echo ""; up::print_history_status; }
			return 0
		fi
	done
	# Fallback: No paginator available
	eval "$base_command"
	[[ "$HIST_ENABLED" == false ]] && { echo ""; up::print_history_status; }
}

# Print the history log file w/ pagination
up::show_history() {
	local -r count=$(up::history_count)
	if [ "$count" -eq 0 ]; then
		up::print_msg "no history entries..."
		[[ "$HIST_ENABLED" == false ]] && up::print_history_status
	elif [[ -f "$LOG_FILE" ]]; then
		# Display a numbered list of history entries in reverse order
		local -r base_history_command="up::print_help_label 'PATH HISTORY'; nl -b a <(tac $LOG_FILE)"
		up::run_with_pagination "$base_history_command"
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
		return "$ERR_BAD_ARG"
	fi

	local -r reversed_index=$(up::reverse_history_index "$index")

	# Extract the directory path from the history file
	local dir="$(sed "${reversed_index}q;d" "$LOG_FILE" | cut -d' ' -f3-)" # log is space delimited

	# Ensure that only valid directory paths are handled
	dir=$(echo "$dir" | sed -e 's/^ *//;s/ *$//') # Trim extra whitespace

	if [[ "$dir" == "$PWD" ]]; then
		up::print_msg "already in: ${PWD_STYLE}$dir${RESET}"
		return "$ERR_NO_CHANGE"
	# Check if the directory exists, then jump to it
	elif [[ -d "$dir" ]]; then
		builtin cd -- "$dir" || up::print_msg "failed to jump to ${ERR_STYLE}$dir${RESET}"
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
		local valid_paths=$(tac "$LOG_FILE" | awk '{print substr($0, index($0, $3))}' | while IFS= read -r path; do
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
				builtin cd -- "$selected_path" || up::print_msg "fzf: failed to change directory to: ${ERR_STYLE}$selected_path${RESET}"
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

# Filters history by recency: $1=<time string by hours or days, e.g., "15min", "2h", "3d">
up::recent_paths() {
	local -r timeframe="$1" # Accepts timeframe (e.g., "1h", "24h")
	[[ ! -f "$LOG_FILE" ]] && up::print_msg "no history file available..." && return 0

	# Convert timeframe to seconds
	local seconds=0
	case "$timeframe" in
		*min) seconds=$(( ${timeframe%min} * 60 )) ;;  # Minutes
		*h) seconds=$(( ${timeframe%h} * 3600 )) ;;    # Hours
		*d) seconds=$(( ${timeframe%d} * 86400 )) ;;   # Days
		*m) seconds=$(( ${timeframe%m} * 2592000 )) ;; # Months (approx. 30 days per month)
		*) up::print_msg "invalid timeframe format: use '1h', '2d', '3m'" && return "$ERR_BAD_ARG" ;;
	esac

	# Current time and cutoff time (in UNIX seconds)
	local current_time=$(date +%s)
	local cutoff_time=$((current_time - seconds))

	# Use Perl to filter paths in the history log
	perl -e '
		use strict;
		use warnings;
		use Time::Local;

		my $cutoff = $ARGV[0]; # Pass cutoff time as argument
		while (<STDIN>) {
			chomp;
			if (/^(\d{4}-\d{2}-\d{2}) (\d{2}:\d{2}:\d{2}) (.+)$/) {
				my $timestamp = "$1 $2";
				my $path = $3;

				# Parse timestamp into epoch time
				if ($timestamp =~ /(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2})/) {
					my ($year, $mon, $mday, $hour, $min, $sec) = ($1, $2, $3, $4, $5, $6);
					my $epoch = timelocal($sec, $min, $hour, $mday, $mon - 1, $year);

					# Print path if it is within the cutoff time
					print "$_\n" if $epoch >= $cutoff;
				}
			}
		}
	' "$cutoff_time" < "$LOG_FILE" | sort -rn
}

# Filter existing paths in the history log and given timeframe using fzf, change into the selected directory
# Missing paths removed from list
# $1=<timeframe, e.g. 15min, 2h, 1m, etc.>
up::filter_recent_history_with_fzf() {
	local timeframe_arg="$1"
	if [[ "$timeframe_arg" =~ ^[0-9]+$ ]]; then
		up::print_msg "no time unit: defaulting to ${timeframe_arg}h timeframe"
		timeframe_arg="${timeframe_arg}h"
	elif [[ ! "$timeframe_arg" =~ ^[0-9]+("min"|h|d|m)$ ]]; then
		up::print_msg "invalid timeframe argument, not in form of <integer>[min|h|d|m]: ${ERR_STYLE}'$timeframe_arg'${RESET}"
		return "$ERR_BAD_ARG"
	fi

	local recent_paths
	recent_paths=$(up::recent_paths "$timeframe_arg")

	# Ensure recent_paths is not empty
	if [[ -z "$recent_paths" ]]; then
		up::print_msg "no recent paths found for $timeframe_arg timeframe"
		return 0
	fi

	# Filter out missing paths from the timeframe
	recent_paths=$(echo "$recent_paths" | awk '{print substr($0, index($0, $3))}' | while IFS= read -r path; do
		[[ -d "$path" ]] && echo "$path"
	done)

	# Append the timeframe to the fzf header
	local FZF_RECENT_HISTOPTS=("${FZF_HISTOPTS[@]}") # Create a copy of the fzf options
	local -r timeframe_header="  󰥌 ${timeframe_arg} ago"
	# Replace the header line for one-time use
	if [[ -n "$BASH_VERSION" ]]; then
		# Bash-compatible iteration
		for i in "${!FZF_RECENT_HISTOPTS[@]}"; do
			if [[ "${FZF_RECENT_HISTOPTS[i]}" == --header=* ]]; then
				FZF_RECENT_HISTOPTS[i]="${FZF_RECENT_HISTOPTS[i]}$timeframe_header"
			fi
		done
	elif [[ -n "$ZSH_VERSION" ]]; then
		# Zsh-compatible iteration
		for i in {1..${#FZF_RECENT_HISTOPTS[@]}}; do
			if [[ "${FZF_RECENT_HISTOPTS[i]}" == --header=* ]]; then
				FZF_RECENT_HISTOPTS[i]="${FZF_RECENT_HISTOPTS[i]}$timeframe_header"
			fi
		done
	else
		up::print_msg "unsupported shell detected"
		return "$ERR_ACCESS"
	fi

	local -r selected_path=$(echo "$recent_paths" | fzf "${FZF_RECENT_HISTOPTS[@]}")

	if [[ -n "$selected_path" ]]; then
		local -r prejump_path="$PWD"
		builtin cd -- "$selected_path" || { up::print_msg "failed to change path"; return "$ERR_BAD_ARG"; }
		up::validate_and_log_history "$prejump_path"
		if [[ "$verbose_mode" == true ]]; then
			local -r msg="jumped to a path from history (${DIR_CHANGE_STYLE}within $timeframe_arg${RESET})"
			up::print_verbose VERBOSE_DEFAULT "$prejump_path" "$msg"
		fi
	else
		up::print_msg "no path selected from $timeframe_arg ago"
	fi
}

# Filter and select the most frequent paths from the history log; missing paths removed from list
up::filter_most_frequent_paths() {
	local -r prejump_path="$PWD"

	[[ "$HIST_ENABLED" == false ]] && up::print_history_status

	if [[ "$(up::history_count)" -eq 0 ]]; then
		up::print_msg "no history entries available..."
		return 0
	fi

	if [[ -f "$LOG_FILE" ]]; then

	# Extract and count occurrences of paths, preserving whitespace
		local frequent_paths
		frequent_paths=$(awk '{print substr($0, index($0, $3))}' "$LOG_FILE" | sort | uniq -c | sort -nr | awk '{print substr($0, index($0, $2))}')
echo "$frequent_paths"
           # gsub(/^ +| +$/, "", path);

		# Check if there are any paths
		if [[ -z "$frequent_paths" ]]; then
			up::print_msg "no valid paths found in most frequently visited..."
			return 0
		fi

		# Filter out missing paths from the frequency list
		frequent_paths=$(echo "$frequent_paths" | while IFS= read -r path; do
			[[ -d $path ]] && echo "$path"
		done)

		# Use fzf to let the user select from the most frequent paths
		local selected_path
		selected_path=$(echo "$frequent_paths" | fzf "${FZF_HISTOPTS[@]}")

		if [[ "$selected_path" == "$PWD" ]]; then
			up::print_msg "already in: ${PWD_STYLE}$selected_path${RESET}"
			return "$ERR_NO_CHANGE"
		elif [[ -n "$selected_path" ]]; then
			if [[ -d "$selected_path" ]]; then
				builtin cd -- "$selected_path" || up::print_msg "failed to change to: ${ERR_STYLE}$selected_path${RESET}"
				if [[ "$verbose_mode" == true ]]; then
					local -r msg="fzf: changed to path in most frequently visited list"
					up::print_verbose VERBOSE_DEFAULT "$prejump_path" "$msg"
				fi
				up::validate_and_log_history "$prejump_path"
			else
				up::print_msg "fzf: not a valid directory: ${ERR_STYLE}$selected_path${RESET}"
				return "$ERR_BAD_ARG"
			fi
		else
			up::print_msg "fzf: no path selected in most frequently visited list"
		fi
	else
		up::print_msg "no history file available..."
		return "$ERR_BAD_ARG"
	fi
}
