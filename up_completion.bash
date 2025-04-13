#-----------------------------------------------------------------------
# _   _ _ __
#| | | | '_ \ _____
#| |_| | |_) |_____|
# \__,_| .__/
#      |_|                  _      _   _
#  ___ ___  _ __ ___  _ __ | | ___| |_(_) ___  _ __
# / __/ _ \| '_ ` _ \| '_ \| |/ _ \ __| |/ _ \| '_ \
#| (_| (_) | | | | | | |_) | |  __/ |_| | (_) | | | |
# \___\___/|_| |_| |_| .__/|_|\___|\__|_|\___/|_| |_|
#                    |_|          _               _
# Tab completion for the `up`    | |__   __ _ ___| |__
# function; `up <tab>` will list | '_ \ / _` / __| '_ \
# all subdirectories for $PWD   _| |_) | (_| \__ \ | | |
#                              (_)_.__/ \__,_|___/_| |_|
# REF: Original completion script was modified from the code
# found at https://github.com/helpermethod/up
#
# TIP: To use this script in Zsh, you must add the following
# lines to .zshrc:
# autoload -U +X compinit && compinit
# autoload -U +X bashcompinit && bashcompinit
# source ~/path/to/up.bash
# source ~/path/to/up-completion.bash
#-----------------------------------------------------------------------

# Removes extra forward slashes and leading slash
_up::normalize_pwd() {
	# Replace multiple slashes with a single slash
	local -r normalized_pwd="${PWD//\/\//\/}"
	# Remove leading slash
	echo "${normalized_pwd#/}"
}

# Escapes special ASCII characters (e.g., `/`, `$`, `*`, etc.) of a given
# directory name: $1=<dir name>
_up::escape_dir_name() {
	local dir_name="$1"
	local escaped_dir_name
	if up::is_command_available "sed"; then
		# Allow Unicode characters to pass thru unescaped and catch multiple
		# space characters in a row
		escaped_dir_name=$(printf '%s' "$dir_name" | sed -E '
			s/([][{}()<>*?|&^$!~`"\\])/\\\1/g;
			s/ /\\ /g
		')
	else # Fallback escaping: should not get here...
		# WARN: This approach causes problems w/ Unicode characters
		# like Japanese, Cyrillic, emojis, etc.
		printf -v escaped_dir_name '%q' "$dir_name"
	fi
	echo "$escaped_dir_name"
}

# Extract base directory names from PWD and append a trailing slash to each
_up::parse_basename_dirs() {
	local pwd_without_leading_slash="$1"
	local dir_name=""  # Buffer for directory segment
	local basenames=() # Array to store directory names

	# Iterate through PWD, respecting all characters; final directory skipped
	for ((i = 0; i < ${#pwd_without_leading_slash}; i++)); do
		char=$(echo "$pwd_without_leading_slash" | cut -c$((i+1))) # Extract character

		if [[ "$char" == "/" ]]; then
			# Append the accumulated directory name with a trailing slash
			basenames+=("$dir_name/")
			dir_name="" # Reset for next segment
		else
			dir_name+="$char" # Append character to buffer
		fi
	done

	# Output results line by line
	printf '%s\n' "${basenames[@]}"
}

# The completion function for `up`
_up() {
	# Edge case: root directory
	[[ "$PWD" == "/" ]] && { COMPREPLY=("/"); return 0; }

	local -r current_word=${COMP_WORDS[COMP_CWORD]}
	local -r pwd_without_leading_slash=$(_up::normalize_pwd)

	# Extract base directory names from PWD and append a trailing slash
	# Capture the output of the function line by line
	while IFS= read -r dir; do
		basenames+=("$dir")
	done < <(_up::parse_basename_dirs "$pwd_without_leading_slash")

	# Add the root directory since PWD is not `/`
	basenames+=(/)

	# Generate tab candidates
	local candidate
	for basename in "${basenames[@]}"; do
		if [[ $basename == "$current_word"* ]]; then
			candidate=$(_up::escape_dir_name "$basename")
			COMPREPLY+=("$candidate")
		fi
	done
}

# Attach completion function to `up` w/o space
complete -o nospace -F _up up
