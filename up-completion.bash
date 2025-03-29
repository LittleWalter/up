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

EXIT_SUCCESS=0
EXIT_FAILURE=1

_up::is_sed_available() {
	if command -v sed &>/dev/null; then
		return $EXIT_SUCCESS
	else
		return $EXIT_FAILURE
	fi
}

_up::normalize_pwd() {
	# Replace multiple slashes with a single slash
	local normalized_pwd=${PWD//\/\//\/}
	# Remove leading slash
	echo ${normalized_pwd:1}
}

_up() {
	# Edge case: root directory
	if [[ $PWD == "/" ]]; then
		COMPREPLY=("/")
		return
	fi

	local -r sed_accessible=$(_up::is_sed_available)
	local -r current_word=${COMP_WORDS[COMP_CWORD]}
	local -r pwd_without_leading_slash=$(_up::normalize_pwd)

	local basenames=()
	# Extract base directory names from $PWD and append slash
	while IFS= read -r -d/; do
		basenames+=("$REPLY/")
	done <<<"$pwd_without_leading_slash"

	# Add the root directory since PWD is not `/`
	basenames+=(/)

	# Generate tab candidates
	local candidate
	for basename in "${basenames[@]}"; do
		if [[ $basename == "$current_word"* ]]; then

			# Escape ASCII special characters automatically
			if $sed_accessible; then
				# Allow Unicode characters to pass thru unescaped
				candidate=$(printf '%s' "$basename" | sed -E 's/([][{}()<>*?|&^$!~`"\\[:space:]])/\\\1/g')
			else # Fallback escaping
				# WARN: This approach causes problems w/ Unicode characters
				# like Japanese, Cyrillic, emojis, etc.
				printf -v candidate '%q' "$basename"
			fi

			COMPREPLY+=("$candidate")
		fi
	done
}

# Attach completion function to `up` w/o space
complete -o nospace -F _up up
