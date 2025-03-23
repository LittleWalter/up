#-----------------------------------------------------------------------
#               _               _
#  _   _ _ __  | |__   __ _ ___| |__
# | | | | '_ \ | '_ \ / _` / __| '_ \
# | |_| | |_) || |_) | (_| \__ \ | | |
#  \__,_| .__(_)_.__/ \__,_|___/_| |_|
#       |_|
# up: an alternative way to quickly change directories upward in the tree
#
# Default is up 1 directory, to parent.
#
# up_by_int and up_by_subdir_name functional decomposition created for
# readability.
#
# NOTE: Magic numbers for exit codes used for errors:
# return 2 = invalid argument passed
# return 3 = no operation a.k.a. no-op, i.e., no directory change
# return 127 = inaccessible directory or `cd` command
#
# USAGE: up <FLAG> [integer | subdirectory name]
#        up [optional: number of subdirectories]
#        up <subdirectory name; must be exact>
#        up 0/ (integer w/ slash to jump to int-named subdir)
#
# REF: https://gitlab.com/dwt1/dotfiles/-/blob/master/.zshrc
#      https://github.com/helpermethod/up/blob/main/up
#-----------------------------------------------------------------------

# Colors displayed for `up` in case these values are not defined already
# REF: https://gist.github.com/jonsuh/3c89c004888dfc7352be
RED="${RED:-\033[0;31m}"
ORANGE="${ORANGE:-\033[0;33m}"
LIGHTGREEN="${LIGHTGREEN:-\033[0;32m}"
NOCOLOR="${NOCOLOR:-\033[0m}"

ERR_CD_ACCESS=127 # inaccessible directory or `cd` command
ERR_NO_CHANGE=3   # no directory change
ERR_BAD_ARG=2     # invalid argument passed

up() {
  # Check if `cd` is available
  if ! command -v cd &>/dev/null; then
    echo -e "up: \`cd\` command not found"
    return ERR_CD_ACCESS
  fi

  # Default verbose to the environment variable, if defined, otherwise false
  local verbose_mode=${_UP_ALWAYS_VERBOSE:-false}

  # Default to go up one dir, no args passed
  local change_dir_arg="1"
  if [ -n "$1" ]; then
    change_dir_arg="$1" # otherwise assume only 1 arg is passed, no flag
  fi

  display_help() { # Display a simple help message for USAGE information
    echo -e "up: jump the directory tree instead of using \`cd ..\`!\n"
    echo "USAGE:"
    echo "  up <FLAG> [integer | subdirectory name]"
    echo "  up [optional: number of subdirectories; default 1]"
    echo "  up <subdirectory name; must be exact>"
    echo "  up <tab> for completion of available subdirectories in PWD"
    echo "  up ~ to change to HOME directory regardless of PWD"
    echo -e "\nOPTIONS/FLAGS:"
    echo "  help, -h, --help        Print help"
    echo "  verbose, -v, --verbose  Print change directory information"
    echo -e "\nEDGE CASES:"
    echo -e "  Append \`/\` if the subdirectory name is an integer or the same as flags."
    echo -e "  To jump to the subdirectory named 0, run: \`up 0/\`."
    echo -e "  To jump to \"-h\", \"--help\", \"help\" subdirectories, run: \`up help/\`, etc."
    echo -e "\nENVIRONMENT VARIABLES:"
    echo "  _UP_ALWAYS_VERBOSE  Always print change directory information; export as true"
  }

  # Process flags
  if [[ "$1" =~ ^(-h|--help|help)$ ]]; then
    display_help
    return 0
  fi
  if [[ "$1" =~ ^(-v|--verbose|verbose)$ ]]; then
    verbose_mode=true
    shift # Consume the verbose flag
    change_dir_arg="${1:-1}"
  fi

  # Helper function: "dir" or "dirs", depending on count: $1=<number of dirs>
  pluralize_dir() {
    local count="$1"
    if [ $count -gt 1 ]; then
       echo "dirs"
    else
      echo "dir"
    fi
  }

  # Helper function: "<int> dir(s)"; call this function after valid directory change
  get_dirs_changed_string() {
    # Determine the number of subdirs jumped
    num_of_dirs_changed() {
      # Counting the number of slashes in the directory path
      # REF: https://unix.stackexchange.com/questions/419837/how-to-count-the-number-of-apparitions-of-a-character-in-a-string
      local old_result=${OLDPWD//[^\/]} # removes all non-slashes from string
      old_result=${#old_result} # counts total chars in string
      local current_result=${PWD//[^\/]}
      current_result=${#current_result}
      if [ "$PWD" = "/" ]; then
        ((old_result=old_result+1)) # Add 1 when navigating to device root directory
      fi
      return $((old_result - current_result))
    }

    num_of_dirs_changed
    local dirs_changed=$?
    local dir_pluralized=$(pluralize_dir $dirs_changed)
    echo "$dirs_changed $dir_pluralized"
  }

  # jump up n subdirs: $1=<number of subdirs>
  up_by_int() {
    local limit="$1"

    # Validate jump limit: default to 1 if no arg provided or negative
    if [ -z "$limit" ] || [ "$limit" -le 0 ]; then
      limit=1
    fi

    # Construct the "../../../etc." string to use w/ `cd`
    local dotted_path=""
    for ((i=1;i<=limit;i++)); do
      dotted_path="../$dotted_path"
    done

    local prejump_path="$PWD"
    local dir_pluralized=$(pluralize_dir $limit)

    # Attempt to change directory
    if ! cd "$dotted_path"; then # perform `cd`; show error if `cd` fails
      echo -e "up: couldn't go up ${RED}$limit $dir_pluralized${NOCOLOR}...";
      return ERR_CD_ACCESS
    fi

    # Check for no change
    if [ "$prejump_path" = "$PWD" ]; then
      echo -e "up: did not jump ${RED}$limit $dir_pluralized${NOCOLOR}, already on root..."
      return ERR_NO_CHANGE # technically not an error, but helpful to indicate to user of no change
    fi

    # Verbose mode output
    if $verbose_mode; then
      local dir_string=$(get_dirs_changed_string)
      echo -e "up: jumped ${ORANGE}$dir_string${NOCOLOR}"
      echo "old: $prejump_path"
      echo -e "pwd: ${LIGHTGREEN}$PWD${NOCOLOR}"
    fi
  }

  # jump up to subdir name: $1=<subdirectory name or HOME path>
  up_by_subdir_name() {
    local subdir_name="$1" # The target subdirectory name
    local prejump_path="$PWD"

    # Special case 1: handle root directory
    if [[ "$subdir_name" == "/" ]]; then
      if [[ "$PWD" == "/" ]]; then
        echo "up: already on the root..."
        return ERR_NO_CHANGE
      fi
      if ! cd "/"; then
        echo "up: failed to navigate to root"
        return ERR_CD_ACCESS
      fi
      # Verbose mode output
      if $verbose_mode; then
        local dir_string=$(get_dirs_changed_string)
        echo -e "up: jumped ${ORANGE}$dir_string${NOCOLOR} to root: ${LIGHTGREEN}$PWD${NOCOLOR}"
        echo "old: $prejump_path"
      fi
      return 0
    fi

    # Special case 2: handle HOME directory
    if [[ "$subdir_name" == "$HOME" || "$subdir_name" == "~" ]]; then
      if [[ "$PWD" == "$HOME" ]]; then
        echo "up: already in the HOME directory"
        return ERR_NO_CHANGE
      fi
      if ! cd "$HOME"; then
        echo -e "up: failed to navigate to HOME: ${RED}$HOME${NOCOLOR}"
        return ERR_CD_ACCESS
      fi
      # Verbose mode output
      if $verbose_mode; then
        if [[ "$prejump_path" == "$HOME"* ]]; then
          local dir_string=$(get_dirs_changed_string)
          echo -e "up: jumped ${ORANGE}$dir_string${NOCOLOR} to HOME: ${LIGHTGREEN}$PWD${NOCOLOR}"
        else # Wasn't in subdir of HOME
          echo -e "up: changed to HOME: ${LIGHTGREEN}$PWD${NOCOLOR}"
        fi
        echo "old: $prejump_path"
      fi
      return 0
    fi

    # General cases start here:
    # Sanitize input: remove trailing slash and everything after; must be a single subdir
    local subdir_name="${subdir_name%/*}"

    # Handle invalid subdirectory case
    if [[ ! "$PWD" == *"$subdir_name"* ]]; then
      echo -e "up: subdirectory ${RED}'$subdir_name'${NOCOLOR} does not exist in:\n$PWD"
      return ERR_BAD_ARG
    fi

    # Attempt to change to the subdirectory
    if ! cd "${PWD%"${PWD##*/"$subdir_name"/}"}"; then
      echo -e "up: failed to navigate to subdirectory ${RED}'$subdir_name'${NOCOLOR}"
      return ERR_CD_ACCESS
    fi

    # Verbose mode output
    if $verbose_mode; then
      local dir_string=$(get_dirs_changed_string)
      echo -e "up: jumped ${ORANGE}$dir_string${NOCOLOR} to nearest: ${LIGHTGREEN}$subdir_name${NOCOLOR}"
      echo "old: $prejump_path"
      echo -e "pwd: ${LIGHTGREEN}$PWD${NOCOLOR}"
    fi
  }

  # Directory change happens here: where action's actually at!
  # First check if the arg is an integer, then jump up the desired number
  if [[ "$change_dir_arg" =~ ^[0-9]+$ ]]; then
    up_by_int $change_dir_arg
  else # Arg is a string or an int/flag w/ slash, try to jump up to the named subdir
    # NOTE: Quotes are important for Bash and whitespace subdirs! Zsh is more forgiving.
    up_by_subdir_name "$change_dir_arg"
  fi
}
