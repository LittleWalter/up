# ╻ ╻┏━┓   ╻ ╻┏━┓┏━┓┏━┓┏━┓┏━╸┏━┓┏━┓ ┏┓ ┏━┓┏━┓╻ ╻
# ┃ ┃┣━┛   ┃╻┃┣┳┛┣━┫┣━┛┣━┛┣╸ ┣┳┛┗━┓ ┣┻┓┣━┫┗━┓┣━┫
# ┗━┛╹  ╺━╸┗┻┛╹┗╸╹ ╹╹  ╹  ┗━╸╹┗╸┗━┛╹┗━┛╹ ╹┗━┛╹ ╹
# `up` wrapper function definitions: `up_passthru`, `ph` (path history)

# Display help message for `up_passthru` function
_up::print_passthru_help() {
	_up::print_help_label "up_passthru for up $VERSION" true
	cat <<EOF
Tracks and captures path changes triggered by directory navigation commands
(cd, etc.), enhancing history management. By default, path histories are
only logged by invoking \`up\` directly.
EOF
	_up::print_help_label "USAGE"
	cat <<EOF
up_passthru <FLAGS|command name>
EOF
	_up::print_help_label "FLAGS"
	cat <<EOF
  -H, --hist-status  Display the status of history logging
  -h, --help         Print help
EOF
	_up::print_help_label "EXAMPLES"
	cat <<EOF
  To track directory changes with \`cd\`, add to your Bash/Zsh configuration:
  alias cd='up_passthru cd'

  Use \`builtin cd -- <path>\` to a skip logging with \`cd\`.

  For zoxide support, add:
  alias z='up_passthru z'
EOF
	_up::print_help_label "RELATED ENVIRONMENT VARIABLES"
	cat <<EOF
  _UP_ENABLE_HIST  Enable history file (Default: false)
  _UP_HISTFILE     Path to the history file (Set as: $LOG_FILE)
  _UP_HISTSIZE     Maximum number of history entries (Set as: $LOG_SIZE)
EOF
}

# Pass directory changes to `up` without affecting `cd`, `zoxide`, `jump`, etc., behavior
# TIP: Add to your configuration:
#      `alias cd='up_passthru cd'` (cd support)
#      `alias z='up_passthru z'` (zoxide support)
up_passthru() {
	# Process flags or print help if no args passed
	if [[ "$1" =~ ^(-h|--help)$ ]] || [[ "$#" -eq 0 ]]; then
		_up::print_passthru_help
		return 0
	fi
	if [[ "$1" =~ ^(-H|--hist-status)$ ]]; then
		_up::print_history_status
		return 0
	fi

	local -r prejump_path="$PWD"
	local -r main_command="$1"
	shift # Consume the dir change command name

	# Check if the command exists
	if ! _up::is_command_available "$main_command"; then
		_up::print_msg "command ${ERR_STYLE}'$main_command'${RESET} not valid for directory changes"
		return "$ERR_ACCESS"
	fi

	# Handle directory changes
	if [[ $# -eq 0 ]]; then
		"$main_command" # Commonly, commands change to HOME w/o args
	else
		"$main_command" "${@}" # Change to specified directory
	fi

	_up::validate_and_log_history "$prejump_path"
	return "$?"
}

# Display help information for `ph` function
_up::print_ph_help() {
	_up::print_help_label "ph for up $VERSION" true
	cat <<EOF
\`ph\` acts as a wrapper around \`up\`, focusing on path history navigation.
Use this function for streamlined directory jumps based on previous paths.
This function is particularly useful in conjunction with \`up_passthru\` to
track global path history.
EOF
	_up::print_help_label "USAGE"
	cat <<EOF
ph <FLAGS> [index|timeframe abbrev.]
EOF
	_up::print_help_label "FLAGS"
	cat <<EOF
  -H, --hist-status  Display the status of history logging
  -L, --list-freq    List historic paths by frequency w/ pagination, descending
  -c, --clear        Clear all history entries or filtered by <integer>(min|h|d|m)
  -f, --fzf          Open \`fzf\` for all valid history entries, if available
  -h, --help         Print help
  -j, --jump         Jump to a path in history by its most recent index
  -l, --list         List the history of paths w/ pagination, ordered by recency
  -m, --fzf-freq     Open \`fzf\` for the most frequently visited historic paths
  -p, --prune        Remove missing paths from history
  -r, --recent       Open \`fzf\` for recent valid paths by <integer>(min|h|d|m)
  -s, --size         Display the current history size
  -v, --verbose      Print additional information about directory changes, etc.
EOF
	_up::print_help_label "EXAMPLES"
	cat <<EOF
  ph         Opens interactive \`fzf\` for all valid history, if available
  ph --fzf   Same as example above but using optional flag
  ph 5       Jumps to 5th most recent path in history
  ph -j 17   Jumps to 17th most recent path using optional flag
  ph --list  Lists the history of paths with pagination
  ph -r 2h   Opens \`fzf\` for valid paths accessed in the last 2 hours
  ph -r      Opens \`fzf\` for valid paths accessed in the last hour (default)
EOF
	_up::print_help_label "RELATED ENVIRONMENT VARIABLES"
	cat <<EOF
  _UP_ENABLE_HIST   Enable history file (Default: false)
  _UP_FZF_HISTOPTS  Set \`fzf\` options for history as an array
  _UP_HISTFILE      Path to the history file (Set as: $LOG_FILE)
  _UP_HISTSIZE      Maximum number of history entries (Set as: $LOG_SIZE)
EOF
}

# `ph` (path history) is a convenience wrapper for history-related
# functionality of `up`; esp. useful for pairing w/ `up_passthru` for global
# path history
ph() {
	local verbose_mode=${_UP_ALWAYS_VERBOSE:-false}
	# Process flags
	local flag_type=FLAG_DEFAULT
	while [[ "$1" =~ ^- ]]; do
		case "$1" in
			-h|--help)
				_up::print_ph_help
				return 0 # Don't bother shifting args, just exit
				;;
			-l|--list)
				up --list-hist # Print contents of LOG_FILE
				return 0
				;;
			-L|--list-freq)
				up --list-freq
				return 0
				;;
			-c|--clear)
				shift
				_up::clear_history "$1"
				return 0
				;;
			-p|--prune)
				_up::prune_history
				return $?
				;;
			-s|--size)
				_up::print_history_size
				return 0
				;;
			-H|--hist-status)
				_up::print_history_status
				return 0
				;;
			-j|--jump)
				flag_type=HIST_JUMP
				shift # Consume flag
				;;
			-f|--fzf)
				flag_type=HIST_FZF
				shift # Consume flag
				;;
			-m|--fzf-freq)
				flag_type=MOST_FREQ_FZF
				shift # Consume flag
				;;
			-r|--recent)
				flag_type=RECENT_HIST_FZF
				shift
				;;
			-v|--verbose)
				verbose_mode=true
				shift # Consume flag
				;;
			-*)
				# Loop through combined single-character flags
				local combined_flags="${1:1}" # Remove leading tack "-"
				local i=0
				while [ $i -lt ${#combined_flags} ]; do
					char=$(echo "$combined_flags" | cut -c $((i + 1)))
					case "$char" in
						h) # Help nested in the shortened flags
							_up::print_ph_help
							return 0
							;;
						l)
							_up::show_history
							return 0
							;;
						L)
							up --list-freq
							return 0
							;;
						c)
							shift
							_up::clear_history "$1"
							return 0
							;;
						p)
							_up::prune_history
							return $?
							;;
						j)
							flag_type=HIST_JUMP
							;;
						f)
							flag_type=HIST_FZF
							;;
						m)
							flag_type=MOST_FREQ_FZF
							;;
						r)
							flag_type=RECENT_HIST_FZF
							;;
						s)
							_up::print_history_size
							return 0
							;;
						H)
							_up::print_history_status
							return 0
							;;
						v)
							verbose_mode=true
							;;
						*)
							_up::print_msg "ph: unknown flag: ${ERR_STYLE}-$char${RESET}"
							return $ERR_BAD_ARG
							;;
					esac
					i=$((i + 1))
				done
				shift
			;;
		esac
	done

	if [[ "$flag_type" -ne $FLAG_DEFAULT ]]; then
		_up::secondary_processing_flags "$1"
	elif [ -n "$1" ]; then
		# Jump to specified history index
		[[ "$verbose_mode" == true ]] && up -vj "$1" && return $?
		up -j "$1"
	else
		# Launch fuzzy finder to jump history
		[[ "$verbose_mode" == true ]] && up -vF && return $?
		up -F
	fi
}
