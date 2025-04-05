# ╻ ╻┏━┓   ╻ ╻╺┳╸╻╻  ┏━┓ ┏┓ ┏━┓┏━┓╻ ╻
# ┃ ┃┣━┛   ┃ ┃ ┃ ┃┃  ┗━┓ ┣┻┓┣━┫┗━┓┣━┫
# ┗━┛╹  ╺━╸┗━┛ ╹ ╹┗━╸┗━┛╹┗━┛╹ ╹┗━┛╹ ╹
# Miscellaneous helper function definitions

# Basic check to check whether a command exists
up::is_command_available() {
	if command -v "$1" &>/dev/null; then
		return "$EXIT_SUCCESS" # NOTE: Truthiness of exit status
	else
		return "$EXIT_FAILURE"
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

# Non-default behavior flag processing. `up` and `ph` have default behavior
# when no args and exactly 1 arg is passed; this deals w/ arbitrary flag
# combinations passed that don't immediately pass return values.
up::secondary_processing_flags() {
	local -r hist_arg="${1:-1}" # defaults to "1", if no arg
	case "$flag_type" in
		HIST_JUMP)
			up::jump_from_history "$hist_arg" # Arg should be a jump index
			;;
		HIST_FZF)
			up::filter_history_with_fzf
			;;
		RECENT_HIST_FZF)
			# Arg should be a timeframe string in hours or days, e.g., "1h", "2d"
			up::filter_recent_history_with_fzf "$hist_arg"
			;;
		PWD_FZF)
			up::filter_ancestors_with_fzf
			;;
	esac
	return $?
}
