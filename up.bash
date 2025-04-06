#-----------------------------------------------------------------------
#               _               _
#  _   _ _ __  | |__   __ _ ___| |__
# | | | | '_ \ | '_ \ / _` / __| '_ \
# | |_| | |_) || |_) | (_| \__ \ | | |
#  \__,_| .__(_)_.__/ \__,_|___/_| |_| For Bash & Zsh
#       |_|
# up: an alternative way to quickly change directories upward!
#     (Plus bonus goodies like optional path history tracking.)
#
# Default without arguments is `up 1` directory, to parent.
#
# USAGE: up <FLAG> [integer | directory name]
#        up [optional: number of directories]
#        up <directory name; default: exact match>
#        up 0/ (integer w/ slash to jump to int-named dir)
#
#-----------------------------------------------------------------------

# Get the absolute path of this file; avoids problems of relative paths
if [ -n "${BASH_SOURCE[0]}" ]; then
	UP_ABS_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
	UP_ABS_PATH="$(cd "$(dirname "$0")" && pwd)"
fi

# Source dependencies
LIBRARY_PATH="$UP_ABS_PATH/up_lib"
source "$LIBRARY_PATH/up_utils.bash" # Load misc helper functions first
source "$LIBRARY_PATH/up_environment_vars.bash" # Constant definitions

if [[ "$HIST_ENABLED" == true ]]; then # Don't pollute config w/ useless functions, if not needed
	source "$LIBRARY_PATH/up_history.bash" # Path history logging
	source "$LIBRARY_PATH/up_wrappers.bash" # `ph` and `up_passthru`
fi

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
Quickly navigate ancestor directories and recall path history to streamline
your workflow—ditch tedious \`cd ..\` commands! Compatible with Bash and Zsh.
EOF
	up::print_help_label "USAGE"
	cat <<EOF
  up <FLAGS> [integer|directory name|\$HOME]
EOF
	up::print_help_label "FLAGS"
	cat <<EOF
  -h, --help     Print help
  -v, --verbose  Print additional information about directory changes

    PWD Navigation:
      -e, --ends-with    Jump to nearest directory regex that ends with <string>
      -f, --fzf          Open \`fzf\` for paths of PWD, if available
      -i, --ignore-case  Enable case-insensitive matching for regex navigation
      -r, --regex        Jump to nearest directory regex matching <string>
      -s, --starts-with  Jump to nearest directory regex that starts with <string>
      -x, --exact        Jump to the nearest directory matching <string> exactly

    Path History Management:
      -F, --fzf-hist     Open \`fzf\` for all valid history entries, if available
      -H, --hist-status  Display the status of history logging
      -R, --fzf-recent   Open \`fzf\` for recent valid paths by <integer>[min|h|d|m]
      -S, --size         Display the current history size
      -c, --clear        Clear all history entries
      -j, --jump-hist    Jump to a path in history by its most recent index
      -l, --list-hist    List the history of paths w/ pagination, ordered by recency
      -p, --prune-hist   Remove missing paths from history
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
  up -R 10min     Open \`fzf\` for valid paths accessed in the last 10 minutes
  up -R 1h        Open \`fzf\` for valid paths accessed in the last hour
EOF
	up::print_help_label "EDGE CASES"
	cat <<EOF
  If the directory name is an integer or matches a flag, append \`/\`.
  Example: To jump to a directory named \`0\`, use \`up 0/\`.
  Example: To jump to directories named \`-h\` or \`--help\`, use \`-h/\` or \`--help/\`.
EOF
	up::print_help_label "ENVIRONMENT VARIABLES"
	cat <<EOF
  _UP_ALWAYS_IGNORE_CASE  Enable case-insensitive regex by default (Default: false)
  _UP_ALWAYS_VERBOSE      Always print change directory information (Default: false)
  _UP_DIR_CHANGE_STYLE    Set ANSI styling for the number of directories jumped
  _UP_ENABLE_HIST         Enable history file (Default: false)
  _UP_ERR_STYLE           Set ANSI styling for error message output
  _UP_FZF_HISTOPTS        Set \`fzf\` options for history (as an array)
  _UP_FZF_PWDOPTS         Set \`fzf\` options for current working directory (as an array)
  _UP_HISTFILE            Path to the history file (set as: $LOG_FILE)
  _UP_HISTSIZE            Maximum number of history entries (set as: $LOG_SIZE)
  _UP_NO_STYLES           Disable all output styling (Default: false)
  _UP_OLDPWD_STYLE        Set ANSI styling for the previous directory (OLDPWD)
  _UP_PWD_STYLE           Set ANSI styling for the current directory (PWD)
  _UP_REGEX_DEFAULT       Use regex as default instead of exact matches (Default: false)
  _UP_REGEX_STYLE         Set ANSI styling for regex patterns
EOF
	up::print_help_label "RELATED COMMANDS"
	cat <<EOF
  \`ph\`: A wrapper function for up, focusing on path history navigation.

  \`up_passthru\`: A background helper function that captures directory
  changes triggered by commands like \`cd\`, \`zoxide\`, \`jump\`, etc.

  To enable these functions, use: \`export _UP_ENABLE_HIST=true\`
EOF
}

# Helper: Return "dir" or "dirs", depending on count: $1=<number of dirs>
up::pluralize_dir() {
	local -r count="$1"
	if [ "$count" -gt 1 ]; then
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
	local old_path=$(up::get_num_of_slashes "$OLDPWD")
	local -r current_path=$(up::get_num_of_slashes "$PWD")
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
	local -r dir_pluralized=$(up::pluralize_dir "$dirs_changed")
	echo "$dirs_changed $dir_pluralized"
}

# Helper: Prints a given $1 value as a string
# TIP: Message format should somewhat mimic core CLI tools like `cd`, `ls`, etc.
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

# Helper: Prints error message concerning history not enabled
# Returns error exit code, if the history is disabled
up::print_history_disabled_warning() {
	if [[ "$HIST_ENABLED" == false ]]; then
		up::print_msg "history logging disabled: use \`export _UP_ENABLE_HIST=true\` in your shell config"
		return "$ERR_ACCESS"
	fi
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

### Function definitions: `up <index>` #################################

# Helper: Validate jump count, defaults to 1 (to parent)
up::validate_jump_index() {
	local -r jump_index="$1"
	if [ -z "$jump_index" ] || [ "$jump_index" -le 0 ]; then
		jump_index=1
	fi
	echo "$(up::remove_leading_zeros "$jump_index")"
}

# Helper: Create the `../../../etc.` string to use with `cd`
up::construct_dotted_path() {
	local -r jump_index="$1"
	local -r maximum_index=$(($(up::get_num_of_slashes "$PWD") + 1))
	if [ "$jump_index" -gt "$maximum_index" ]; then
		local -r dotted_path=$(printf "../%.0s" $(seq 1 "$maximum_index"))
	else
		local -r dotted_path=$(printf "../%.0s" $(seq 1 "$jump_index"))
	fi
	echo "$dotted_path"
}

# Jump up n dirs: $1=<number of dirs>
up::cd_by_int() {
	local -r jump_index=$(up::validate_jump_index "$1")
	local -r dotted_path=$(up::construct_dotted_path "$jump_index")

	local -r prejump_path="$PWD"
	local -r dir_pluralized=$(up::pluralize_dir "$jump_index")

	# Attempt to change directory
	if ! cd "$dotted_path"; then # perform `cd`; show error if `cd` fails
		up::print_msg "couldn't go up ${ERR_STYLE}$jump_index $dir_pluralized${RESET}..."
		return "$ERR_ACCESS"
	fi

	# Check for no change
	if [ "$prejump_path" = "$PWD" ]; then
		up::print_msg "did not jump ${ERR_STYLE}$jump_index $dir_pluralized${RESET}, already on root..."
		return "$ERR_NO_CHANGE" # technically not an error, but helpful to indicate to user of no change"
	elif [[ "$HIST_ENABLED" == true ]]; then
		up::validate_and_log_history "$prejump_path"
	fi

	# Verbose mode output on successful dir change
	if [[ "$verbose_mode" == true ]]; then
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
		return "$ERR_BAD_ARG"
	fi

	# Attempt to change to the directory
	if ! cd "${PWD%"${PWD##*/"$dir_name"/}"}"; then
		up::print_msg "failed to navigate to directory: ${ERR_STYLE}'$dir_name'${RESET}"
		return "$ERR_ACCESS"
	elif [[ "$HIST_ENABLED" == true ]]; then
		up::validate_and_log_history "$prejump_path"
	fi

	# Verbose mode output on successful dir change
	if [[ "$verbose_mode" == true ]]; then
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
	while [ "$i" -ge 0 ]; do
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
				if [[ "$verbose_mode" == true ]]; then
					local dir_string=$(up::get_dirs_changed_string)
					local msg="jumped ${DIR_CHANGE_STYLE}$dir_string${RESET} to nearest regex: ${REGEX_STYLE}'$dir_regex'${RESET}"
					if $ignore_case; then
						msg="${msg} (case insensitive)"
					fi
					up::print_verbose DEFAULT "$prejump_path" "$msg"
				fi
				[[ "$HIST_ENABLED" == true ]] && up::validate_and_log_history "$prejump_path"
				return 0
			else
				up::print_msg "failed to navigate to regex: ${ERR_STYLE}'$dir_regex'${RESET}"
				return "$ERR_ACCESS"
			fi
		fi
		i=$((i - 1))  # Decrement the loop index
	done

	# If no match is found
	up::print_msg "no directory regex matches ${ERR_STYLE}'$dir_regex'${RESET} in:"
	up::print_pwd
	return "$ERR_BAD_ARG"
}

# Jumps to dir name: $1=<directory name|regex|HOME>
up::cd_by_dir_name() {
	local dir_name="$1" # The target directory name
	local -r prejump_path="$PWD"

	# Special case 1: handle root directory
	if [[ "$dir_name" == "/" ]]; then
		if [[ "$PWD" == "/" ]]; then
			up::print_msg "already on the root..."
			return "$ERR_NO_CHANGE"
		fi
		if ! cd "/"; then
			up::print_msg "failed to navigate to root"
			return "$ERR_ACCESS"
		elif [[ "$HIST_ENABLED" == true ]]; then
			up::validate_and_log_history "$prejump_path"
		fi
		# Verbose mode output on successful dir change
		if [[ "$verbose_mode" == true ]]; then
			local dir_string=$(up::get_dirs_changed_string)
			local msg="jumped ${DIR_CHANGE_STYLE}$dir_string${RESET} to root: ${PWD_STYLE}$PWD${RESET}"
			up::print_verbose VERBOSE_TWO_LINES "$prejump_path" "$msg"
		fi
		return 0
	fi

	# Special case 2: handle HOME path
	if [[ "$dir_name" == "$HOME" || "$dir_name" == "~" ]]; then
		if [[ "$PWD" == "$HOME" ]]; then
			up::print_msg "already in the HOME directory"
			return "$ERR_NO_CHANGE"
		fi
		if ! cd "$HOME"; then
			up::print_msg "failed to navigate to HOME: ${ERR_STYLE}$HOME${RESET}"
			return "$ERR_ACCESS"
		elif [[ "$HIST_ENABLED" == true ]]; then
			up::validate_and_log_history "$prejump_path"
		fi
		# Verbose mode output on successful dir change
		if [[ "$verbose_mode" == true ]]; then
			local -r msg="changed to HOME: ${PWD_STYLE}$PWD${RESET}"
			if [[ "$prejump_path" == "$HOME"* ]]; then
				local -r dir_string=$(up::get_dirs_changed_string)
				msg="jumped ${DIR_CHANGE_STYLE}$dir_string${RESET} to HOME: ${PWD_STYLE}$PWD${RESET}"
			fi
			up::print_verbose VERBOSE_TWO_LINES "$prejump_path" "$msg"
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

# Filter paths in PWD using fzf and change into the selected directory
up::filter_ancestors_with_fzf() {
	# Verify that fzf is installed
	if ! up::is_command_available "fzf"; then
		up::print_msg "\`fzf\` not found: check installation of fuzzy finder"
		return "$ERR_ACCESS"
	fi

	# Constuct array of ancestor full paths
	local pwd="$PWD"
	local paths=()
	while [[ "$pwd" != "/" ]]; do
		paths+=("$pwd")
		pwd=$(dirname "$pwd") # Go up one level
	done
	paths+=("/") # Add root directory

	# Use fzf for interactive fuzzy selection
	local -r selected_path=$(printf "%s\n" "${paths[@]}" | fzf "${FZF_PWDOPTS[@]}")

	# Handle case where no selection is made
	if [[ -z "$selected_path" ]]; then
		up::print_msg "fzf: no ancestor path selected"
		return 0
	fi

	# Change into the selected ancestor path
	if [[ -d "$selected_path" ]]; then
		local -r prejump_path="$PWD"
		if [[ "$selected_path" != "$prejump_path" ]]; then
			if cd "$selected_path" && [[ "$verbose_mode" == true ]]; then
				local -r dir_string=$(up::get_dirs_changed_string)
				local -r msg="fzf: jumped ${DIR_CHANGE_STYLE}$dir_string${RESET}"
				up::print_verbose VERBOSE_DEFAULT "$prejump_path" "$msg"
			fi
			[[ "$HIST_ENABLED" == true ]] && up::validate_and_log_history "$prejump_path"
		else
			up::print_msg "fzf: did not jump up tree"
			return "$ERR_NO_CHANGE"
		fi
	else
		up::print_msg "fzf: invalid ancestor path: ${ERR_STYLE}$selected_path${RESET}"
		return "$ERR_ACCESS"
	fi
}

### `up <int|dir name|regex>` ##########################################

up() {
	# Check if `cd` is available
	if ! up::is_command_available "cd"; then
		up::print_msg "\`cd\` command not found"
		return "$ERR_ACCESS"
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
	local flag_type="$FLAG_DEFAULT"
	if ! [[ "$1" =~ /$ ]]; then # directory args always end in slash
		local prejump_path="$PWD"
		if [[ "$1" == "-" ]] && cd -; then
			[[ "$HIST_ENABLED" == true ]] && up::validate_and_log_history "$prejump_path"
			return 0
		fi
		while [[ "$1" =~ ^- ]]; do
			case "$1" in
				-h|--help)
					up::print_help
					return 0 # Don't bother shifting args, just exit
					;;
				-l|--list-hist)
					up::print_history_disabled_warning || return 0
					up::show_history
					return 0
					;;
				-c|--clear)
					up::print_history_disabled_warning || return 0
					up::clear_history
					return 0
					;;
				-p|--prune-hist)
					up::print_history_disabled_warning || return 0
					up::prune_history
					return $?
					;;
				-S|--size)
					up::print_history_disabled_warning || return 0
					up::print_history_size
					return 0
					;;
				-H|--hist-status)
					up::print_history_disabled_warning || return 0
					up::print_history_status
					return 0
					;;
				-j|--jump-hist)
					up::print_history_disabled_warning || return 0
					flag_type=HIST_JUMP
					shift # Consume flag
					change_dir_arg="${1:-1}"
					;;
				-f|--fzf)
					flag_type=PWD_FZF
					shift # Consume flag
					change_dir_arg="${1:-1}"
					;;
				-F|--fzf-hist)
					up::print_history_disabled_warning || return 0
					flag_type=HIST_FZF
					shift # Consume flag
					;;
				-R|--fzf-recent)
					up::print_history_disabled_warning || return 0
					flag_type=RECENT_HIST_FZF
					shift
					change_dir_arg="${1:-1}"
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
								up::print_history_disabled_warning || return 0
								up::show_history
								return 0
								;;
							c)
								up::print_history_disabled_warning || return 0
								up::clear_history
								return 0
								;;
							p)
								up::print_history_disabled_warning || return 0
								up::prune_history
								return $?
								;;
							j)
								up::print_history_disabled_warning || return 0
								flag_type=HIST_JUMP
								;;
							f)
								flag_type=PWD_FZF
								;;
							F)
								up::print_history_disabled_warning || return 0
								flag_type=HIST_FZF
								;;
							R)
								up::print_history_disabled_warning || return 0
								flag_type=RECENT_HIST_FZF
								;;
							S)
								up::print_history_disabled_warning || return 0
								up::print_history_size
								return 0
								;;
							H)
								up::print_history_disabled_warning || return 0
								up::print_history_status
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
								up::print_msg "unknown flag: ${ERR_STYLE}-$char${RESET}"
								return "$ERR_BAD_ARG"
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
	if [[ "$flag_type" -ne $FLAG_DEFAULT ]]; then
		up::secondary_processing_flags "$change_dir_arg"
	# Check if the arg is an integer, then jump up the desired number
	elif [[ "$change_dir_arg" =~ ^[0-9]+$ ]]; then
		up::cd_by_int "$change_dir_arg"
	else # Arg is a string or an int/flag w/ slash, try to jump up to the named dir
		up::cd_by_dir_name "$change_dir_arg" "$match_mode"
	fi
	return $? # Return exit code of directory change
}
