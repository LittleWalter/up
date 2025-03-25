#-----------------------------------------------------------------------
#               _               _
#  _   _ _ __  | |__   __ _ ___| |__
# | | | | '_ \ | '_ \ / _` / __| '_ \
# | |_| | |_) || |_) | (_| \__ \ | | |
#  \__,_| .__(_)_.__/ \__,_|___/_| |_|
#       |_|
# up: an alternative way to quickly change directories upward in the tree
#
# Default without arguments is up 1 directory, to parent.
#
# USAGE: up <FLAG> [integer | subdirectory name]
#        up [optional: number of subdirectories]
#        up <subdirectory name; must be exact>
#        up 0/ (integer w/ slash to jump to int-named subdir)
#
# REF: https://gitlab.com/dwt1/dotfiles/-/blob/master/.zshrc
#      https://github.com/helpermethod/up/blob/main/up
#-----------------------------------------------------------------------

### Constant definitions: avoid magic numbers! #########################

VERSION="1.0"

# Set styling constants: colors displayed for `up`, mostly for verbose mode
if ${_UP_NO_STYLES:-false}; then
	LABEL_STYLE=""
	DIR_CHANGE_STYLE=""
	ERR_STYLE=""
	OLDPWD_STYLE=""
	PWD_STYLE=""
	RESET=""
else
	# REF: For fallback color definitions see https://gist.github.com/jonsuh/3c89c004888dfc7352be
	LABEL_STYLE="\033[4m\033[1m"
	DIR_CHANGE_STYLE="${_UP_DIR_CHANGE_STYLE:-${ORANGE:-\033[0;33m}}"
	ERR_STYLE="${_UP_ERR_STYLE:-${RED:-\033[0;31m}}"
	OLDPWD_STYLE="${_UP_OLDPWD_STYLE:-${LIGHTGRAY:-\033[1;37m}}"
	PWD_STYLE="${_UP_PWD_STYLE:-${LIGHTGREEN:-\033[0;32m}}"
	RESET="\033[0m"
fi

# Error exit code constants
ERR_BAD_ARG=2     # invalid argument passed
ERR_CD_ACCESS=127 # inaccessible directory or `cd` command
ERR_NO_CHANGE=3   # no directory change

# Verbose mode constants
DEFAULT=0
TWO_LINES=2

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
Jump the directory tree instead of using \`cd ..\`!
A function written for Bash and Zsh.
EOF
	up::print_help_label "USAGE"
	cat <<EOF
  up <FLAG> [integer | subdirectory name]
  up [optional: number of subdirectories; default 1]
  up <subdirectory name; must be exact>
  up <tab> for completion of available subdirectories in PWD
  up ~ to change to HOME directory regardless of PWD
EOF
	up::print_help_label "OPTIONS/FLAGS"
	cat <<EOF
  help, -h, --help        Print help
  verbose, -v, --verbose  Print change directory information
EOF
	up::print_help_label "EDGE CASES"
	cat <<EOF
  Append \`/\` if the subdirectory name is an integer or the same as flags.
  To jump to the subdirectory named 0, run: \`up 0/\`.
  To jump to "-h", "--help", "help" subdirectories, run: \`up -h/\`, etc.
EOF
	up::print_help_label "ENVIRONMENT VARIABLES"
	cat <<EOF
  _UP_ALWAYS_VERBOSE    Always print change directory information; export as true
  _UP_DIR_CHANGE_STYLE  ANSI styling of number of directories jumped (verbose mode)
  _UP_ERR_STYLE         ANSI styling of error message output
  _UP_NO_STYLES         Turn output styling off; export as true
  _UP_OLDPWD_STYLE      ANSI styling of OLDPWD after jump (verbose mode)
  _UP_PWD_STYLE         ANSI styling of PWD after jump (verbose mode)
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

	up::print_msg "$3"

	case $1 in
		TWO_LINES)
			up::print_oldpwd "$oldpwd"
			;;
		DEFAULT|*) # Standard verbose output
			up::print_oldpwd "$oldpwd"
			up::print_pwd
			;;
	esac
}

# jump up n subdirs: $1=<number of subdirs>
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
		up::print_verbose DEFAULT "$prejump_path" "$msg"
	fi
}

# jump up to subdir name: $1=<subdirectory name or HOME path>
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
			up::print_verbose TWO_LINES $prejump_path $msg
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
			up::print_verbose TWO_LINES $prejump_path $msg
		fi
		return 0
	fi

	# General cases start here

	# Sanitize input: remove trailing slash and everything after; must be a single subdir
	local subdir_name="${subdir_name%/*}"

	# Handle invalid subdirectory case: the subdir must be sandwiched between slashes
	if ! [[ "$PWD" =~ "/$subdir_name/" ]]; then
		up::print_msg "subdirectory ${ERR_STYLE}'$subdir_name'${RESET} does not exist in:"
		up::print_pwd
		return ERR_BAD_ARG
	fi

	# Attempt to change to the subdirectory
	if ! cd "${PWD%"${PWD##*/"$subdir_name"/}"}"; then
		up::print_msg "failed to navigate to subdirectory ${ERR_STYLE}'$subdir_name'${RESET}"
		return ERR_CD_ACCESS
	fi

	# Verbose mode output on successful dir change
	if $verbose_mode; then
		local dir_string=$(up::get_dirs_changed_string)
		local msg="jumped ${DIR_CHANGE_STYLE}$dir_string${RESET} to nearest: ${PWD_STYLE}$subdir_name${RESET}"
		up::print_verbose DEFAULT "$prejump_path" "$msg"
	fi
}

up() {
	# Check if `cd` is available
	if ! command -v cd &>/dev/null; then
		up::print_msg "\`cd\` command not found"
		return ERR_CD_ACCESS
	fi

	# Default verbose to the environment variable, if defined, otherwise false
	local verbose_mode=${_UP_ALWAYS_VERBOSE:-false}

	# Default to go up one dir, no args passed
	local change_dir_arg="1"
	if [ -n "$1" ]; then
		change_dir_arg="$1" # otherwise assume only 1 arg is passed, no flag
	fi

	# Process flags
	if [[ "$1" =~ ^(-h|--help|help)$ ]]; then
		up::print_help
		return 0
	fi
	if [[ "$1" =~ ^(-v|--verbose|verbose)$ ]]; then
		verbose_mode=true
		shift # Consume the verbose flag
		change_dir_arg="${1:-1}"
	fi

	# Directory change happens here: where action's actually at!
	# First check if the arg is an integer, then jump up the desired number
	if [[ "$change_dir_arg" =~ ^[0-9]+$ ]]; then
		up::cd_by_int $change_dir_arg
	else # Arg is a string or an int/flag w/ slash, try to jump up to the named subdir
		# NOTE: Quotes are important for Bash and whitespace subdirs! Zsh is more forgiving.
		up::cd_by_subdir_name "$change_dir_arg"
	fi
}

