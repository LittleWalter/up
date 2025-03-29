#-----------------------------------------------------------------------
#               _               _
#  _   _ _ __  | |__   __ _ ___| |__
# | | | | '_ \ | '_ \ / _` / __| '_ \
# | |_| | |_) || |_) | (_| \__ \ | | |
#  \__,_| .__(_)_.__/ \__,_|___/_| |_|
#       |_|
# up: an alternative way to quickly change directories upward!
#
# Default without arguments is up 1 directory, to parent.
#
# USAGE: up <FLAG> [integer | directory name]
#        up [optional: number of directories]
#        up <directory name; default: exact match>
#        up 0/ (integer w/ slash to jump to int-named dir)
#
# REF: https://gitlab.com/dwt1/dotfiles/-/blob/master/.zshrc
#      https://github.com/helpermethod/up/blob/main/up
#-----------------------------------------------------------------------

### Constant definitions: Avoid magic values! ##########################

VERSION="1.0.0"

LOG_FILE="${_UP_HISTFILE:-${XDG_CACHE_HOME:-$HOME/.cache}/up_history.log}"

# Create the log file if it doesn't exist
if [ ! -f "$LOG_FILE" ]; then
	mkdir -p "$(dirname "$LOG_FILE")"  # Create the directory if it doesn't exist
	touch "$LOG_FILE"
fi

LOG_SIZE_DEFAULT=250
LOG_SIZE=${_UP_HISTSIZE:-$LOG_SIZE_DEFAULT}

# Set styling constants: colors displayed for `up`, mostly for verbose mode
if ${_UP_NO_STYLES:-false}; then
	LABEL_STYLE=""
	DIR_CHANGE_STYLE=""
	ERR_STYLE=""
	OLDPWD_STYLE=""
	PWD_STYLE=""
	REGEX_STYLE=""
	RESET=""
else
	# REF: For fallback color definitions see https://gist.github.com/jonsuh/3c89c004888dfc7352be
	LABEL_STYLE="\033[4m\033[1m" # Underline
	DIR_CHANGE_STYLE="${_UP_DIR_CHANGE_STYLE:-${ORANGE:-\033[0;33m}}"
	ERR_STYLE="${_UP_ERR_STYLE:-${RED:-\033[0;31m}}"
	OLDPWD_STYLE="${_UP_OLDPWD_STYLE:-${LIGHTGRAY:-\033[1;37m}}"
	PWD_STYLE="${_UP_PWD_STYLE:-${LIGHTGREEN:-\033[0;32m}}"
	REGEX_STYLE="${_UP_REGEX_STYLE:-${CYAN:-\033[0;36m}}"
	RESET="\033[0m"
fi

# Error exit code constants
ERR_BAD_ARG=2     # invalid argument passed
ERR_ACCESS=127    # inaccessible directory or `cd` or other command
ERR_NO_CHANGE=3   # no directory change

# Verbose mode constants
VERBOSE_TWO_LINES=2
VERBOSE_DEFAULT=3

# Match type constants: for named dirs
MATCH_EXACT=1
MATCH_REGEX=2
MATCH_START=3
MATCH_END=4

### Function definitions: print and related helpers ####################

# Helper: Label styling for helper sections
# $1=<label text>
# $2=<title Boolean flag>
up::print_help_label() {
	local -r is_title=${2:-false}
	if $is_title; then
		echo -e "${LABEL_STYLE}$1${RESET}\n"
	else
		echo -e "\n${LABEL_STYLE}$1:${RESET}"
	fi
}

# Display a simple help message for USAGE information
up::print_help() {
	up::print_help_label "up $VERSION" true
	cat <<EOF
Jump the directory tree instead of using \`cd ..\` chains!
A function written for Bash and Zsh.
EOF
	up::print_help_label "USAGE"
	cat <<EOF
  up <FLAGS> [integer|directory name|\$HOME]
EOF
	up::print_help_label "FLAGS"
	cat <<EOF
  -S, --size         Displays the current history size
  -c, --clear        Clears all history entries
  -e, --ends-with    Jumps to nearest directory regex ending with
  -f, --fzf          Opens \`fzf\` (fuzzy finder) for history, if available
  -h, --help         Print help
  -i, --ignore-case  Enables case-insensitivity for regex matching
  -j, --jump-hist    Jumps to a path in history by its most recent index
  -l, --list-hist    Lists the history of paths w/ pagination, ordered by recency
  -r, --regex        Jumps to the nearest directory regex match
  -s, --starts-with  Jumps to the nearest directory regex starting with
  -v, --verbose      Prints additional change directory information
  -x, --exact        Jumps to the nearest exact directory match
EOF
	up::print_help_label "EXAMPLES"
	cat <<EOF
  up              Jump to parent directory
  up 2            Jump two levels up in the directory tree
  up ~            Go to HOME path regardless of PWD
  up -            Go to previous path (OLDPWD)
  up <tab>        Display completion list of ancestor directories
  up -r src       Jump to nearest directory matching 'src' (regex)
  up -ir 'logs$'  Jump to nearest directory ending with 'logs' (ignore case)
  up -eiv logs    Equivalent to previous example but with verbose output
EOF
	up::print_help_label "EDGE CASES"
	cat <<EOF
  If the directory name is an integer or matches a flag, append \`/\`.
  Example: To jump to a directory named \`0\`, use \`up 0/\`.
  Example: To jump to directories named \`-h\` or \`--help\`, use \`-h/\` or \`--help/\`.
EOF
	up::print_help_label "ENVIRONMENT VARIABLES"
	cat <<EOF
  _UP_ALWAYS_IGNORE_CASE  Enable case-insensitive regex by defaul (set to \`true\`)
  _UP_ALWAYS_VERBOSE      Always print change directory information (set to \`true\`)
  _UP_DIR_CHANGE_STYLE    Specify ANSI styling for the number of directories jumped
  _UP_ERR_STYLE           Specify ANSI styling for error message output
  _UP_HISTFILE            Path to the history file (set as: $LOG_FILE)
  _UP_HISTSIZE            Maximum number of history entries (set as: $LOG_SIZE)
  _UP_NO_STYLES           Disable output styling entirely (set to \`true\`)
  _UP_OLDPWD_STYLE        Specify ANSI styling for previous directory (OLDPWD)
  _UP_PWD_STYLE           Specify ANSI styling for the current directory (PWD)
  _UP_REGEX_DEFAULT       Use regex as the default instead of exact matches (set to \`true\`)
  _UP_REGEX_STYLE         Specify ANSI styling of regex patterns
EOF
	up::print_help_label "RELATED COMMANDS"
	cat <<EOF

  \`ph\`: A wrapper function for up, focusing on path history navigation.

  \`up_passthru\`: A background helper function that captures directory
  changes triggered by commands like \`cd\`, \`zoxide\`, \`jump\`, etc.
EOF
}

# Helper: Return "dir" or "dirs", depending on count: $1=<number of dirs>
up::pluralize_dir() {
	local -r count="$1"
	if [ $count -gt 1 ]; then
		echo "dirs"
	else
		echo "dir"
	fi
}

# REF: https://unix.stackexchange.com/questions/419837/how-to-count-the-number-of-apparitions-of-a-character-in-a-string
up::get_num_of_slashes() {
	# Counting the number of slashes in the directory path
	local -r slashes=${1//[^\/]} # removes all non-slashes from string
	echo ${#slashes} # counts total chars in string
}

# Helper: Returns the number of dirs changed
# NOTE: Only called within up::get_dirs_changed_string
up::num_of_dirs_changed() {
	local old_path=$(up::get_num_of_slashes $OLDPWD)
	local -r current_path=$(up::get_num_of_slashes $PWD)
	if [ "$PWD" = "/" ]; then
		((old_path=old_path+1)) # Add 1 when navigating to device root directory
	fi
	echo $((old_path - current_path))
}

# Helper: Constructs "<int> dir(s)" string
# USE: Call this function after valid directory change
up::get_dirs_changed_string() {
	# Determine the number of dirs jumped
	local -r dirs_changed=$(up::num_of_dirs_changed)
	local -r dir_pluralized=$(up::pluralize_dir $dirs_changed)
	echo "$dirs_changed $dir_pluralized"
}

# Helper: Prints a given $1 value as a string
# USE: Message format should somewhat mimic core CLI tools like `cd`, `ls`, etc.
up::print_msg() {
	if [ -n "$1" ]; then
		echo -e "up: $1"
	fi
}

# Helper: Prints stylized PWD
up::print_pwd() {
	echo -e "pwd: ${PWD_STYLE}$PWD${RESET}"
}

# Helper: Prints stylized OLDPWD or $1=<prejump_path>
up::print_oldpwd() {
	local -r oldpwd=${1:-OLDPWD}
	echo -e "old: ${OLDPWD_STYLE}$oldpwd${RESET}"
}

# Print output for verbose mode:
# $1=<version of verbose output to print, 2 or 3 lines>
# $2=<previous path>
# $3=<optional: top message>
up::print_verbose() {
	local -r oldpwd="$2"

	up::print_msg "$3" # always print the message

	case "$1" in
		VERBOSE_TWO_LINES)
			up::print_oldpwd "$oldpwd"
			;;
		VERBOSE_DEFAULT|*) # Standard verbose output
			up::print_oldpwd "$oldpwd"
			up::print_pwd
			;;
	esac
}

### Function definitions: `up` History #################################

# Checks to see if path changed before adding line to history
# $1=<prejump_path>
up::validate_and_log_history() {
	local -r prejump_path="$1"
	if [[ "$PWD" != "$prejump_path" ]]; then
		up::log_history "$PWD"
	else
		return $ERR_NO_CHANGE
	fi
}

# Add a line to the history log w/ time and date: $1=<path to log>
up::log_history() {
	local -r dir="$1"
	local -r timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
	echo "$timestamp $dir" >> "$LOG_FILE"
	# Trim log file
	tail -n $LOG_SIZE "$LOG_FILE" > "$LOG_FILE.tmp" && mv "$LOG_FILE.tmp" "$LOG_FILE"
}

# Clear history log file
up::clear_history() {
	local -r count=$(up::history_count)
	if [[ -f "$LOG_FILE" ]] && [[ "$count" -gt 0 ]]; then
		: > "$LOG_FILE" # Truncate to clear
		up::print_msg "history file cleared: $LOG_FILE"
	else
		up::print_msg "no history to clear..."
	fi
}

# Number of entries (lines) in the history log file
up::history_count() {
	echo $(wc -l < "$LOG_FILE")
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
}

# Print the history log file w/ pagination
up::show_history() {
	local -r count=$(up::history_count)
	if [ "$count" -eq 0 ]; then
		up::print_msg "no history entries..."
	elif [[ -f "$LOG_FILE" ]]; then
		# Display a numbered list of history entries in reverse order
		local -r base_history_command='up::print_help_label "PATH HISTORY"; nl -b a <(tac "$LOG_FILE")'

		# Array of paginators (commands w/o options)
		local paginators=("bat" "less" "most" "more")

		for paginator in "${paginators[@]}"; do
			if command -v "$paginator" &>/dev/null; then
				case "$paginator" in
					bat)
						eval "$base_history_command" | bat --style="plain"
						;;
					*) # paginators w/o options
						eval "$base_history_command" | "$paginator"
						;;
				esac
				return
			fi
		done

		# Fallback: No paginator available
		eval "$base_history_command"
	else
		up::print_msg "no history file available..."
	fi
}

# History log file is in chronological order (oldest to newest), so we
# must get the reverse index since `up::jump_from_history` outputs
# bottom up (i.e., most recent dir)
# $1=<index>
up::reverse_history_index() {
	local index="$1"
	index=$(up::remove_leading_zeros "$index")
	local -r count=$(up::history_count)
	echo $((count - index + 1))
}

# Jump to a history path in LOG_FILE: $1=<history line number>
up::jump_from_history() {
	local index="$1"
	local -r prejump_path="$PWD"

	# Validate index input as integer value
	if ! [[ "$index" =~ ^[0-9]+$ ]]; then
		up::print_msg "not a valid history index: ${ERR_STYLE}'$index'${RESET}"
		return $ERR_BAD_ARG
	fi

	index=$(up::reverse_history_index "$index")

	# Get the total number of lines in the log file
	local -r total_lines=$(up::history_count)

	# Check if the index is within the valid range
	if (( index < 1 || index > total_lines )); then
		up::print_msg "history index is out of range: ${ERR_STYLE}$index${RESET}"
		return $ERR_BAD_ARG
	fi

	# Extract the directory path from the history file
	local dir="$(sed "${index}q;d" "$LOG_FILE" | awk '{print $3 " " $4 " " $5}')"

	# Ensure that only valid directory paths are handled
	dir=$(echo "$dir" | sed -e 's/^ *//;s/ *$//') # Trim extra whitespace

	if [[ "$dir" == "$PWD" ]]; then
		up::print_msg "already in: ${PWD_STYLE}$dir${RESET}"
		return $ERR_NO_CHANGE
	# Check if the directory exists, then jump to it
	elif [[ -d "$dir" ]]; then
		cd "$dir" || up::print_msg "failed to jump to ${ERR_STYLE}$dir${RESET}"
		up::log_history "$dir"
		if $verbose_mode; then
			local -r msg="jumped to ${DIR_CHANGE_STYLE}index $index${RESET} in history log"
			up::print_verbose VERBOSE_DEFAULT $prejump_path $msg
		fi
	else
		up::print_msg "directory does not exist: ${ERR_STYLE}$dir${RESET}"
		return $ERR_BAD_ARG
	fi
}

# Filter paths in the history log using fzf and change into the selected directory
up::filter_history_with_fzf() {
	if ! command -v fzf &>/dev/null; then
		up::print_msg "\`fzf\` command not found: check installation of fuzzy finder"
		return $ERR_ACCESS
	elif [[ "$(up::history_count)" -eq 0 ]]; then
		up::print_msg "no history entries..."
		return 0
	fi
	if [[ -f "$LOG_FILE" ]]; then
		local -r selected_path=$(tac "$LOG_FILE" | awk '{$1=$2=""; print substr($0, 3)}' | fzf --height=50% --layout=reverse --prompt="Path: " --header='󰌑 cd |  ^P ( ^J/ ^K)' --preview='tree -C {}' --bind='ctrl-p:toggle-preview' --preview-window=hidden --bind='ctrl-j:preview-page-down,ctrl-k:preview-page-up')
		if [[ "$selected_path" == "$PWD" ]]; then
			up::print_msg "already in: $selected_path"
			return $ERR_NO_CHANGE
		elif [[ -n "$selected_path" ]]; then
			if [[ -d "$selected_path" ]]; then
				cd "$selected_path" || up::print_msg "failed to change directory to: ${ERR_STYLE}$selected_path${RESET}"
				up::print_msg "changed directory to: ${PWD_STYLE}$selected_path${RESET}"
				up::log_history "$PWD"
			else
				up::print_msg "not a valid directory: ${ERR_STYLE}$selected_path${RESET}"
				return $ERR_BAD_ARG
			fi
		else
			up::print_msg "no path selected"
		fi
	else
		up::print_msg "no history file available to filter"
		return $ERR_BAD_ARG
	fi
}

### Function definitions: `up <count>` #################################

# Helper: Validate jump count, defaults to 1 (to parent)
up::validate_jump_index() {
	local -r jump_index="$1"
	if [ -z "$jump_index" ] || [ "$jump_index" -le 0 ]; then
		jump_index=1
	fi
	echo $(up::remove_leading_zeros "$jump_index")
}

# Helper: Create the `../../../etc.` string to use with `cd`
up::construct_dotted_path() {
	local -r jump_index="$1"
	local dotted_path=""
	for ((i=1; i<=jump_index; i++)); do
		dotted_path="../$dotted_path"
	done
	echo "$dotted_path"
}

# Jump up n dirs: $1=<number of dirs>
up::cd_by_int() {
	local -r jump_index=$(up::validate_jump_index "$1")
	local -r dotted_path=$(up::construct_dotted_path "$jump_index")

	local -r prejump_path="$PWD"
	local -r dir_pluralized=$(up::pluralize_dir $jump_index)

	# Attempt to change directory
	if ! cd "$dotted_path"; then # perform `cd`; show error if `cd` fails
		up::print_msg "couldn't go up ${ERR_STYLE}$jump_index $dir_pluralized${RESET}..."
		return $ERR_ACCESS
	fi

	# Check for no change
	if [ "$prejump_path" = "$PWD" ]; then
		up::print_msg "did not jump ${ERR_STYLE}$jump_index $dir_pluralized${RESET}, already on root..."
		return $ERR_NO_CHANGE # technically not an error, but helpful to indicate to user of no change
	else
		up::log_history "$PWD"
	fi

	# Verbose mode output on successful dir change
	if $verbose_mode; then
		local dir_string=$(up::get_dirs_changed_string)
		local msg="jumped ${DIR_CHANGE_STYLE}$dir_string${RESET}"
		up::print_verbose VERBOSE_DEFAULT "$prejump_path" "$msg"
	fi
}

### Function definitions: `up <dir name|regex>` ########################

# Jumps to an exact directory match, default behavior: $1=<directory name>
up::cd_by_dir_exact() {
	local -r dir_name="$1"
	local -r prejump_path="$PWD"

	# Handle invalid directory case: must be sandwiched between slashes
	if ! [[ "$PWD" =~ "/$dir_name/" ]]; then
		up::print_msg "directory ${ERR_STYLE}'$dir_name'${RESET} does not exist in:"
		up::print_pwd
		return $ERR_BAD_ARG
	fi

	# Attempt to change to the directory
	if ! cd "${PWD%"${PWD##*/"$dir_name"/}"}"; then
		up::print_msg "failed to navigate to directory: ${ERR_STYLE}'$dir_name'${RESET}"
		return $ERR_ACCESS
	else
		up::log_history "$PWD"
	fi

	# Verbose mode output on successful dir change
	if $verbose_mode; then
		local dir_string=$(up::get_dirs_changed_string)
		local msg="jumped ${DIR_CHANGE_STYLE}$dir_string${RESET} to nearest: ${PWD_STYLE}$dir_name${RESET}"
		up::print_verbose VERBOSE_DEFAULT "$prejump_path" "$msg"
	fi
}

# Jumps to nearest directory matching user-specified regex: $1=<user regex>
up::cd_by_dir_regex() {
	local -r dir_regex="$1" # Original/user input regex; used for output
	local working_regex="$1" # This regex changes depending on case sensitivity
	local -r prejump_path="$PWD"

	# Bash and Zsh handle case insensitivity differently
	if $ignore_case; then
		if [[ -n "$BASH_VERSION" ]]; then
			# NOTE: `tr` is a core utility, should be available on most Unix-like systems
			# Instead of using Perl-style regex patterns of (?i) to ignore case, this
			# should cover compatibility issues on older versions of Bash.
			working_regex=$(echo "$working_regex" | tr '[:upper:]' '[:lower:]')
		else
			working_regex=${working_regex:l}
		fi
	fi

	# Normalize PWD to replace multiple slashes with a single slash
	# This catches rare edge cases of accidentally malformed paths
	local normalized_pwd=${PWD//\/\//\/}
	local -r pwd_without_leading_slash=${normalized_pwd:1}

	local basenames=()
	# Extract base directory names from $PWD
	while IFS= read -r -d/; do
		basenames+=("$REPLY")
	done <<<"$pwd_without_leading_slash"

	# Initialize loop index
	local i=${#basenames[@]}

	# Iterate over the array from the last element to the first
	while [ $i -ge 0 ]; do
		local current_dir="${basenames[i]}"

		# Tranform chars: case insensitivity
		if $ignore_case; then
			if [[ -n "$BASH_VERSION" ]]; then
				current_dir=$(echo "$current_dir" | tr '[:upper:]' '[:lower:]')
			else
				current_dir=${current_dir:l}
			fi
		fi

		# Check if the current dir matches the regex; regex errors suppressed
		# TODO: Check validity of regex patterns?
		if [[ "$current_dir" =~ $working_regex ]] 2>/dev/null; then
			# Reconstruct the path up to the matching directory
			# NOTE: Bash and Zsh handle array slices differently
			if [[ -n "$BASH_VERSION" ]]; then
				# Bash array slicing
				local target_path=$(printf "/%s" "${basenames[@]:0:i+1}")
			else
				# Zsh array slicing
				local target_path=$(printf "/%s" "${basenames[@]:0:$i}")
			fi

			if cd "$target_path"; then
				# Verbose mode output on successful directory change
				if $verbose_mode; then
					local dir_string=$(up::get_dirs_changed_string)
					local msg="jumped ${DIR_CHANGE_STYLE}$dir_string${RESET} to nearest regex: ${REGEX_STYLE}'$dir_regex'${RESET}"
					if $ignore_case; then
						msg="${msg} (case insensitive)"
					fi
					up::print_verbose DEFAULT "$prejump_path" "$msg"
				fi
				up::log_history "$PWD"
				return 0
			else
				up::print_msg "failed to navigate to regex: ${ERR_STYLE}'$dir_regex'${RESET}"
				return $ERR_ACCESS
			fi
		fi
		i=$((i - 1))  # Decrement the loop index
	done

	# If no match is found
	up::print_msg "no directory regex matches ${ERR_STYLE}'$dir_regex'${RESET} in:"
	up::print_pwd
	return $ERR_BAD_ARG
}

# Jumps to dir name: $1=<directory name|regex|HOME>
up::cd_by_dir_name() {
	local dir_name="$1" # The target directory name
	local -r prejump_path="$PWD"

	# Special case 1: handle root directory
	if [[ "$dir_name" == "/" ]]; then
		if [[ "$PWD" == "/" ]]; then
			up::print_msg "already on the root..."
			return $ERR_NO_CHANGE
		fi
		if ! cd "/"; then
			up::print_msg "failed to navigate to root"
			return $ERR_ACCESS
		else
			up::log_history "$PWD"
		fi
		# Verbose mode output on successful dir change
		if $verbose_mode; then
			local dir_string=$(up::get_dirs_changed_string)
			local msg="jumped ${DIR_CHANGE_STYLE}$dir_string${RESET} to root: ${PWD_STYLE}$PWD${RESET}"
			up::print_verbose VERBOSE_TWO_LINES $prejump_path $msg
		fi
		return 0
	fi

	# Special case 2: handle HOME path
	if [[ "$dir_name" == "$HOME" || "$dir_name" == "~" ]]; then
		if [[ "$PWD" == "$HOME" ]]; then
			up::print_msg "already in the HOME directory"
			return $ERR_NO_CHANGE
		fi
		if ! cd "$HOME"; then
			up::print_msg "failed to navigate to HOME: ${ERR_STYLE}$HOME${RESET}"
			return $ERR_ACCESS
		else
			up::log_history "$PWD"
		fi
		# Verbose mode output on successful dir change
		if $verbose_mode; then
			local -r msg="changed to HOME: ${PWD_STYLE}$PWD${RESET}"
			if [[ "$prejump_path" == "$HOME"* ]]; then
				local -r dir_string=$(up::get_dirs_changed_string)
				msg="jumped ${DIR_CHANGE_STYLE}$dir_string${RESET} to HOME: ${PWD_STYLE}$PWD${RESET}"
			fi
			up::print_verbose VERBOSE_TWO_LINES $prejump_path $msg
		fi
		return 0
	fi

	# General cases start here

	# Sanitize input: remove trailing slash and everything after; must be a single dir
	dir_name="${dir_name%/*}"

	case "$match_mode" in
		MATCH_START)
			up::cd_by_dir_regex "^${dir_name}"
			;;
		MATCH_END)
			up::cd_by_dir_regex "${dir_name}$"
			;;
		MATCH_REGEX)
			up::cd_by_dir_regex "${dir_name}"
			;;
		MATCH_EXACT|*) # Default: exact directory match
			up::cd_by_dir_exact "$dir_name"
			;;
	esac
}

### `up <int|dir name|regex>` ##########################################

up() {
	# Check if `cd` is available
	if ! command -v cd &>/dev/null; then
		up::print_msg "\`cd\` command not found"
		return $ERR_ACCESS
	fi

	# Default verbose to the environment variable, if defined, otherwise false
	local verbose_mode=${_UP_ALWAYS_VERBOSE:-false}
	# Default matching mode to exact directory names
	local match_mode=MATCH_EXACT
	if ${_UP_REGEX_DEFAULT:-false}; then
		match_mode=MATCH_REGEX
	fi
	# Default to case sensitive regex
	local ignore_case=${_UP_ALWAYS_IGNORE_CASE:-false}

	# Default to go up one dir, no args or flags passed
	local change_dir_arg="1"
	if [ -n "$1" ]; then
		change_dir_arg="$1" # otherwise assume only 1 arg is passed, no flags
	fi

	# Process flags
	if ! [[ "$1" =~ /$ ]]; then # directory args always end in slash
		[[ "$1" == "-" ]] && cd - && up::log_history "$PWD" && return 0
		while [[ "$1" =~ ^- ]]; do
			case "$1" in
				-h|--help)
					up::print_help
					return 0 # Don't bother shifting args, just exit
					;;
				-l|--list-hist)
					up::show_history
					return 0 # Don't bother shifting args, just exit
					;;
				-c|--clear)
					up::clear_history
					return 0
					;;
				-S|--size)
					up::print_history_size
					return 0
					;;
				-j|--jump-hist)
					shift # Next arg must be line number in history log file
					up::jump_from_history "$1"
					return $?
					;;
				-f|--fzf)
					up::filter_history_with_fzf
					return $?
					;;
				-v|--verbose)
					verbose_mode=true
					shift # Consume flag
					change_dir_arg="${1:-1}"
					;;
				-r|--regex)
					match_mode=MATCH_REGEX
					shift
					change_dir_arg="${1:-1}"
					;;
				-s|--starts-with)
					match_mode=MATCH_START
					shift
					change_dir_arg="${1:-1}"
					;;
				-e|--ends-with)
					match_mode=MATCH_END
					shift
					change_dir_arg="${1:-1}"
					;;
				-i|--ignore-case)
					ignore_case=true
					shift
					change_dir_arg="${1:-1}"
					;;
				-x|--exact)
					match_mode=MATCH_EXACT
					shift
					change_dir_arg="${1:-1}"
					;;
				-*)
					# Loop through combined single-character flags
					local combined_flags="${1:1}" # Remove leading tack "-"
					local i=0
					while [ $i -lt ${#combined_flags} ]; do
						char=$(echo "$combined_flags" | cut -c $((i + 1)))
						case "$char" in
							h) # Help nested in the shortened flags
								up::print_help
								return 0
								;;
							l)
								up::show_history
								return 0
								;;
							c)
								up::clear_history
								return 0
								;;
							j)
								shift
								up::jump_from_history "$1"
								return $?
								;;
							f)
								up::filter_history_with_fzf
								return $?
								;;
							S)
								up::print_history_size
								return 0
								;;
							v)
								verbose_mode=true
								;;
							r)
								match_mode=MATCH_REGEX
								;;
							s)
								match_mode=MATCH_START
								;;
							e)
								match_mode=MATCH_END
								;;
							x)
								match_mode=MATCH_EXACT
								;;
							i)
								ignore_case=true
								;;
							*)
								up::print_msg "unknown flag: ${ERR_STYLE}-$char"${RESET}
								return $ERR_BAD_ARG
								;;
						esac
						i=$((i + 1))
					done
					shift
					change_dir_arg="${1:-1}"
				;;
			esac
		done
	fi

	# Directory change happens here: where the action's actually at!
	# First check if the arg is an integer, then jump up the desired number
	if [[ "$change_dir_arg" =~ ^[0-9]+$ ]]; then
		up::cd_by_int "$change_dir_arg"
	else # Arg is a string or an int/flag w/ slash, try to jump up to the named dir
		up::cd_by_dir_name "$change_dir_arg" "$match_mode"
	fi
	return $? # Return exit code of directory change
}

### Miscellaneous function definition(s) ##############################

# Display help message for `up_passthru` function
up::print_passthru_help() {
	up::print_help_label "up_passthru for up $VERSION" true
	cat <<EOF
Tracks and captures path changes triggered by directory navigation commands
(cd, etc.), enhancing history management. By default, path histories are
only logged by invoking \`up\` directly.
EOF
	up::print_help_label "USAGE"
	cat <<EOF
up_passthru <FLAGS|command name>
EOF
	up::print_help_label "FLAGS"
	cat <<EOF
  -h, --help  Print help
EOF
	up::print_help_label "EXAMPLES"
	cat <<EOF
  To track directory changes with \`cd\`, add to your Bash/Zsh configuration:
  alias cd='up_passthru cd'

  For zoxide support, add:
  alias z='up_passthru z'
EOF
	up::print_help_label "RELATED ENVIRONMENT VARIABLES"
	cat <<EOF
  _UP_HISTFILE  Path to the history file (set as: $LOG_FILE)
  _UP_HISTSIZE  Maximum number of history entries (set as: $LOG_SIZE)
EOF
}

# Pass directory changes to `up` without affecting `cd`, `zoxide`, `jump`, etc., behavior
# TIP: Add to your configuration:
#      `alias cd='up_passthru cd'` (cd support)
#      `alias z='up_passthru z'` (zoxide support)
up_passthru() {
	# Process flags or print help if no args passed
	if [[ "$1" =~ ^(-h|--help)$ ]] || [[ "$#" -eq 0 ]]; then
		up::print_passthru_help
		return 0
	fi

	local -r prejump_path="$PWD"
	local -r main_command="$1"
	shift # Consume the dir change command name

	# Check if the command exists
	if ! command -v $main_command &>/dev/null; then
		up::print_msg "command ${ERR_STYLE}'$main_command'${RESET} not found"
		return $ERR_ACCESS
	fi

	# Handle directory changes
	if [[ $# -eq 0 ]]; then
		"$main_command" # Commonly, commands change to HOME w/o args
	else
		"$main_command" "${@}" # Change to specified directory
	fi

	return $(up::validate_and_log_history "$prejump_path")
}

# Display help information for `ph` function
up::print_ph_help() {
	up::print_help_label "ph for up $VERSION" true
	cat <<EOF
\`ph\` acts as a wrapper around \`up\`, focusing on path history navigation.
Use this function for streamlined directory jumps based on previous paths.
This function is especially useful in conjunction with \`up_passthru\` to
track global path history.
EOF
	up::print_help_label "USAGE"
	cat <<EOF
ph <FLAG> [jump index]
EOF
	up::print_help_label "FLAGS"
	cat <<EOF
  -c, --clear  Clears all history entries
  -f, --fzf    Opens \`fzf\` (fuzzy finder) for history, if available
  -h, --help   Print help
  -j, --jump   Jumps to a path in history by its most recent index
  -l, --list   Lists the history of paths w/ pagination, ordered by recency
  -s, --size   Displays the current history size
EOF
	up::print_help_label "EXAMPLES"
	cat <<EOF
  ph         Opens interactive \`fzf\`, if available
  ph --fzf   Same as example above but using optional flag
  ph 2       Jumps to previous path in history
  ph 5       Jumps the 5th most recent path in history
  ph -j 17   Jumps to 17th most recent using optional flag
  ph --list  Lists the history of paths with pagination
EOF
	up::print_help_label "RELATED ENVIRONMENT VARIABLES"
	cat <<EOF
  _UP_HISTFILE  Path to the history file (set as: $LOG_FILE)
  _UP_HISTSIZE  Maximum number of history entries (set as: $LOG_SIZE)
EOF
}

# `ph` (path history) is a convenience wrapper for path 
# history-related functionality of `up`
ph() {
	# Process flags
	if [[ "$1" =~ ^(-h|--help)$ ]]; then
		up::print_ph_help
		return 0
	fi
	if [[ "$1" =~ ^(-l|--list)$ ]]; then
		up --list-hist # Print contents of LOG_FILE
		return $?
	fi
	if [[ "$1" =~ ^(-s|--size)$ ]]; then
		up::print_history_size
		return 0
	fi
	if [[ "$1" =~ ^(-f|--fzf)$ ]]; then # Optional flag kept for consistency
		up --fzf
		return $?
	fi
	if [[ "$1" =~ ^(-c|--clear)$ ]]; then
		up --clear # Clear out history file contents
		return 0
	fi
	if [[ "$1" =~ ^(-j|--jump)$ ]]; then # Optional flag kept for consistency
		shift # Consume flag
		up --jump-hist "$1"
		return $?
	fi

	# Jump to specified history index (by most recent), or launch fuzzy finder
	if [ -n "$1" ]; then
		up --jump-hist "$1"
	else
		up --fzf
	fi
}

# Remove leading 0's, base-10 conversion: $1=<integer string>
up::remove_leading_zeros() {
	local -r integer="$1"
	if [[ "$integer" =~ ^[0-9]+$ ]]; then
		echo $((10#$integer))
	else
		up::print_msg "did not remove leading zeros from non-integer: ${ERR_STYLE}$integer${RESET}"
	fi
}
