# ╻ ╻┏━┓   ╻ ╻╺┳╸╻╻  ┏━┓ ┏┓ ┏━┓┏━┓╻ ╻
# ┃ ┃┣━┛   ┃ ┃ ┃ ┃┃  ┗━┓ ┣┻┓┣━┫┗━┓┣━┫
# ┗━┛╹  ╺━╸┗━┛ ╹ ╹┗━╸┗━┛╹┗━┛╹ ╹┗━┛╹ ╹
# Miscellaneous helper function definitions

# Basic check to check whether a command exists
_up::is_command_available() {
	if command -v "$1" &>/dev/null; then
		return "$EXIT_SUCCESS" # NOTE: Truthiness of exit status
	else
		return "$EXIT_FAILURE"
	fi
}

# Remove leading 0's, base-10 conversion: $1=<integer string>
_up::remove_leading_zeros() {
	local -r integer="$1"
	if [[ "$integer" =~ ^[0-9]+$ ]]; then
		echo $((10#$integer))
	else
		_up::print_msg "did not remove leading zeros from non-integer: ${ERR_STYLE}$integer${RESET}"
	fi
}

# Pluralizes most file system terms.
# $1=<base word to pluralize> $2=<count>
# NOTE: Many exceptions in English not correctly pluralized such as mouse to mice,
# child to children, criterion to criteria, sheep to sheep, foot to feet, etc.
_up::pluralize() {
	local word_base="$1"  # Input word to pluralize
	local count="$2"      # Count of items

	# Default to singular unless count > 1 or count == 0
	local word_result="$word_base"
	if [[ "$count" -gt 1 || "$count" -eq 0 ]]; then
		if [[ "$word_base" != "key" ]] && [[ "$word_base" =~ y$ ]]; then
			# Words ending in "y" become "ies" (e.g., "directory" -> "directories")
			word_result="${word_base:0:-1}ies"
		elif [[ "$word_base" =~ s$ ]]; then
			# Singular words ending in "s" pluralize with "es" (e.g., "class" -> "classes")
			word_result="${word_base}es"
		else
			# Most common pluralization: add "s" (e.g., "file" -> "files")
			word_result="${word_base}s"
		fi
	fi

	echo "$word_result" # Output the pluralized word
}

# Non-default behavior flag processing. `up` and `ph` have default behavior
# when no args and exactly 1 arg is passed; this deals w/ arbitrary flag
# combinations passed that don't immediately pass return values.
_up::secondary_processing_flags() {
	local -r hist_arg="${1:-1}" # defaults to "1", if no arg
	case "$flag_type" in
		HIST_JUMP)
			_up::jump_from_history "$hist_arg" # Arg should be a jump index
			;;
		HIST_FZF)
			_up::filter_history_with_fzf
			;;
		RECENT_HIST_FZF)
			# Arg should be a timeframe string in hours or days, e.g., "1h", "2d"
			_up::filter_recent_history_with_fzf "$hist_arg"
			;;
		MOST_FREQ_FZF)
			_up::filter_most_frequent_paths
			;;
		PWD_FZF)
			_up::filter_ancestors_with_fzf
			;;
	esac
	return $?
}
