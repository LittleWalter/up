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
# USAGE: up <FLAG> [integer | subdirectory name]
#        up [optional: number of subdirectories]
#        up <subdirectory name; default: exact match>
#        up 0/ (integer w/ slash to jump to int-named subdir)
#
# REF: https://gitlab.com/dwt1/dotfiles/-/blob/master/.zshrc
#      https://github.com/helpermethod/up/blob/main/up
#-----------------------------------------------------------------------

### Constant definitions: avoid magic values! ##########################

VERSION="1.0.0"

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
ERR_CD_ACCESS=127 # inaccessible directory or `cd` command
ERR_NO_CHANGE=3   # no directory change

# Verbose mode constants
VERBOSE_TWO_LINES=2
VERBOSE_DEFAULT=3

# Match type constants: for named subdirs
MATCH_EXACT=1
MATCH_REGEX=2
MATCH_START=3
MATCH_END=4

### Function definitions ###############################################

# Helper function: label styling for sections
# $1=<label text>
# $2=<title Boolean flag>
up::print_help_label() {
	local is_title=${2:-false}
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
  up <FLAGS> [integer|subdirectory name]
  up [optional: number of subdirectories; default 1]
  up <subdirectory name; default exact match>
  up <tab>  Completion of available subdirectories in PWD
  up ~      To HOME directory regardless of PWD
EOF
	up::print_help_label "FLAGS"
	cat <<EOF
  -e, --ends-with    Jump to nearest subdirectory regex ending with
  -h, --help         Print help
  -i, --ignore-case  Jump to nearest subdirectory regex, case insensitive
  -r, --regex        Jump to nearest subdirectory regex match
  -s, --starts-with  Jump to nearest subdirectory regex starting with
  -v, --verbose      Print change directory information
  -x, --exact        Jump to exact match of nearest subdirectory
EOF
	up::print_help_label "EDGE CASES"
	cat <<EOF
  Append \`/\` if the subdirectory name is an integer or the same as flags.
  To jump to the subdirectory named 0, run: \`up 0/\`.
  To jump to "-h", "--help" subdirectories, run: \`up -h/\`, etc.
EOF
	up::print_help_label "ENVIRONMENT VARIABLES"
	cat <<EOF
  _UP_ALWAYS_IGNORE_CASE  Always use case insensitive regex; export as true
  _UP_ALWAYS_VERBOSE      Always print change directory information; export as true
  _UP_DIR_CHANGE_STYLE    ANSI styling of number of directories jumped (verbose mode)
  _UP_ERR_STYLE           ANSI styling of error message output
  _UP_NO_STYLES           Turn output styling off; export as true
  _UP_OLDPWD_STYLE        ANSI styling of OLDPWD after jump (verbose mode)
  _UP_PWD_STYLE           ANSI styling of PWD after jump (verbose mode)
  _UP_REGEX_DEFAULT       Use regex as default instead of exact match; export as true
  _UP_REGEX_STYLE         ANSI styling of regex patterns (verbose mode)
EOF
}

# Helper function: "dir" or "dirs", depending on count: $1=<number of dirs>
up::pluralize_dir() {
	local count="$1"
	if [ $count -gt 1 ]; then
		echo "dirs"
	else
		echo "dir"
	fi
}

# Helper function: returns the number of dirs changed
# NOTE: Only called within up::get_dirs_changed_string
up::num_of_dirs_changed() {
	# Counting the number of slashes in the directory path
	# REF: https://unix.stackexchange.com/questions/419837/how-to-count-the-number-of-apparitions-of-a-character-in-a-string
	local old_path=${OLDPWD//[^\/]} # removes all non-slashes from string
	old_path=${#old_path} # counts total chars in string
	local current_path=${PWD//[^\/]}
	current_path=${#current_path}
	if [ "$PWD" = "/" ]; then
		((old_path=old_path+1)) # Add 1 when navigating to device root directory
	fi
	return $((old_path - current_path))
}

# Helper function: constructs "<int> dir(s)" string
# USE: Call this function after valid directory change
up::get_dirs_changed_string() {
	# Determine the number of subdirs jumped
	up::num_of_dirs_changed
	local dirs_changed=$?
	local dir_pluralized=$(up::pluralize_dir $dirs_changed)
	echo "$dirs_changed $dir_pluralized"
}

# Helper function: prints a given $1 value as a string
# USE: Message format should somewhat mimic core CLI tools like `cd`, `ls`, etc.
up::print_msg() {
	if [ -n "$1" ]; then
		echo -e "up: $1"
	fi
}

# Helper function: prints stylized PWD
up::print_pwd() {
	echo -e "pwd: ${PWD_STYLE}$PWD${RESET}"
}

# Helper function: prints stylized OLDPWD or $1=<prejump_path>
up::print_oldpwd() {
	local oldpwd=${1:-OLDPWD}
	echo -e "old: ${OLDPWD_STYLE}$oldpwd${RESET}"
}

# Print output for verbose mode:
# $1=<version of verbose output to print, 2 or 3 lines>
# $2=<previous path>
# $3=<optional: top message>
up::print_verbose() {
	local oldpwd="$2"

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

# Jump up n subdirs: $1=<number of subdirs>
up::cd_by_int() {
	local limit="$1"

	# Validate jump limit: default to 1 if no arg provided or negative value
	if [ -z "$limit" ] || [ "$limit" -le 0 ]; then
		limit=1
	fi

	# Construct the "../../../etc." string to use w/ `cd`
	local dotted_path=""
	for ((i=1;i<=limit;i++)); do
		dotted_path="../$dotted_path"
	done

	local prejump_path="$PWD"
	local dir_pluralized=$(up::pluralize_dir $limit)

	# Attempt to change directory
	if ! cd "$dotted_path"; then # perform `cd`; show error if `cd` fails
		up::print_msg "couldn't go up ${ERR_STYLE}$limit $dir_pluralized${RESET}..."
		return ERR_CD_ACCESS
	fi

	# Check for no change
	if [ "$prejump_path" = "$PWD" ]; then
		up::print_msg "did not jump ${ERR_STYLE}$limit $dir_pluralized${RESET}, already on root..."
		return ERR_NO_CHANGE # technically not an error, but helpful to indicate to user of no change
	fi

	# Verbose mode output on successful dir change
	if $verbose_mode; then
		local dir_string=$(up::get_dirs_changed_string)
		local msg="jumped ${DIR_CHANGE_STYLE}$dir_string${RESET}"
		up::print_verbose VERBOSE_DEFAULT "$prejump_path" "$msg"
	fi
}

# Jumps to an exact subdirectory match, default behavior: $1=<subdirectory name>
up::cd_by_subdir_exact() {
	local subdir_name="$1"
	local prejump_path="$PWD"

	# Handle invalid subdirectory case: must be sandwiched between slashes
	if ! [[ "$PWD" =~ "/$subdir_name/" ]]; then
		up::print_msg "subdirectory ${ERR_STYLE}'$subdir_name'${RESET} does not exist in:"
		up::print_pwd
		return ERR_BAD_ARG
	fi

	# Attempt to change to the subdirectory
	if ! cd "${PWD%"${PWD##*/"$subdir_name"/}"}"; then
		up::print_msg "failed to navigate to subdirectory: ${ERR_STYLE}'$subdir_name'${RESET}"
		return ERR_CD_ACCESS
	fi

	# Verbose mode output on successful dir change
	if $verbose_mode; then
		local dir_string=$(up::get_dirs_changed_string)
		local msg="jumped ${DIR_CHANGE_STYLE}$dir_string${RESET} to nearest: ${PWD_STYLE}$subdir_name${RESET}"
		up::print_verbose VERBOSE_DEFAULT "$prejump_path" "$msg"
	fi
}

# Jumps to nearest subdirectory matching user-specified regex: $1=<user regex>
up::cd_by_subdir_regex() {
	local subdir_regex="$1"  # Original/user input regex; used for output
	local working_regex="$1" # This regex changes depending on case sensitivity
	local prejump_path="$PWD"

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
		local current_subdir="${basenames[i]}"

		# Tranform chars: case insensitivity
		if $ignore_case; then
			if [[ -n "$BASH_VERSION" ]]; then
				current_subdir=$(echo "$current_subdir" | tr '[:upper:]' '[:lower:]')
			else
				current_subdir=${current_subdir:l}
			fi
		fi

		# Check if the current subdir matches the regex; regex errors suppressed
		# TODO: Check validity of regex patterns?
		if [[ "$current_subdir" =~ $working_regex ]] 2>/dev/null; then
			# Reconstruct the path up to the matching subdirectory
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
					local msg="jumped ${DIR_CHANGE_STYLE}$dir_string${RESET} to nearest regex: ${REGEX_STYLE}'$subdir_regex'${RESET}"
					if $ignore_case; then
						msg="${msg} (case insensitive)"
					fi
					up::print_verbose DEFAULT "$prejump_path" "$msg"
				fi
				return 0
			else
				up::print_msg "failed to navigate to regex: ${ERR_STYLE}'$subdir_regex'${RESET}"
				return ERR_CD_ACCESS
			fi
		fi
		i=$((i - 1))  # Decrement the loop index
	done

	# If no match is found
	up::print_msg "no subdirectory regex matches ${ERR_STYLE}'$subdir_regex'${RESET} in:"
	up::print_pwd
	return ERR_BAD_ARG
}

# Jumps to subdir name: $1=<subdirectory name|regex|HOME>
up::cd_by_subdir_name() {
	local subdir_name="$1" # The target subdirectory name
	local prejump_path="$PWD"

	# Special case 1: handle root directory
	if [[ "$subdir_name" == "/" ]]; then
		if [[ "$PWD" == "/" ]]; then
			up::print_msg "already on the root..."
			return ERR_NO_CHANGE
		fi
		if ! cd "/"; then
			up::print_msg "failed to navigate to root"
			return ERR_CD_ACCESS
		fi
		# Verbose mode output on successful dir change
		if $verbose_mode; then
			local dir_string=$(up::get_dirs_changed_string)
			local msg="jumped ${DIR_CHANGE_STYLE}$dir_string${RESET} to root: ${PWD_STYLE}$PWD${RESET}"
			up::print_verbose VERBOSE_TWO_LINES $prejump_path $msg
		fi
		return 0
	fi

	# Special case 2: handle HOME directory
	if [[ "$subdir_name" == "$HOME" || "$subdir_name" == "~" ]]; then
		if [[ "$PWD" == "$HOME" ]]; then
			up::print_msg "already in the HOME directory"
			return ERR_NO_CHANGE
		fi
		if ! cd "$HOME"; then
			up::print_msg "failed to navigate to HOME: ${ERR_STYLE}$HOME${RESET}"
			return ERR_CD_ACCESS
		fi
		# Verbose mode output on successful dir change
		if $verbose_mode; then
			local msg="changed to HOME: ${PWD_STYLE}$PWD${RESET}"
			if [[ "$prejump_path" == "$HOME"* ]]; then
				local dir_string=$(up::get_dirs_changed_string)
				msg="jumped ${DIR_CHANGE_STYLE}$dir_string${RESET} to HOME: ${PWD_STYLE}$PWD${RESET}"
			fi
			up::print_verbose VERBOSE_TWO_LINES $prejump_path $msg
		fi
		return 0
	fi

	# General cases start here

	# Sanitize input: remove trailing slash and everything after; must be a single subdir
	local subdir_name="${subdir_name%/*}"

	case "$match_mode" in
		MATCH_START)
			up::cd_by_subdir_regex "^${subdir_name}"
			;;
		MATCH_END)
			up::cd_by_subdir_regex "${subdir_name}$"
			;;
		MATCH_REGEX)
			up::cd_by_subdir_regex "${subdir_name}"
			;;
		MATCH_EXACT|*) # Default: exact subdirectory match
			up::cd_by_subdir_exact "$subdir_name"
			;;
	esac
}

up() {
	# Check if `cd` is available
	if ! command -v cd &>/dev/null; then
		up::print_msg "\`cd\` command not found"
		return ERR_CD_ACCESS
	fi

	# Default verbose to the environment variable, if defined, otherwise false
	local verbose_mode=${_UP_ALWAYS_VERBOSE:-false}
	# Default matching mode to exact subdirectory names
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
		while [[ "$1" =~ ^- ]]; do
			case "$1" in
				-h|--help)
					up::print_help
					return 0
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
								return ERR_BAD_ARG
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
	else # Arg is a string or an int/flag w/ slash, try to jump up to the named subdir
		up::cd_by_subdir_name "$change_dir_arg" "$match_mode"
	fi
	return $? # Return exit code of directory change
}
