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
_up() {
	local -r current_word=${COMP_WORDS[COMP_CWORD]}

	# Edge case: root directory
	if [[ $PWD == "/" ]]; then
		COMPREPLY=("/")
		return
	fi

	# Normalize PWD to replace multiple slashes with a single slash
	# This catches rare edge cases of accidentally malformed paths
	local normalized_pwd=${PWD//\/\//\/} 
	local -r pwd_without_leading_slash=${normalized_pwd:1}

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
			# Escape special characters in the candidate
			# WARN: This approach causes problems w/ unicode characters
			# like Japanese, Cyrillic, emojis, etc. If you only use
			# Latin-based characters, this is fine for hitting tab to
			# complete escaped sequences
			#printf -v candidate '%q' "$basename"
			#COMPREPLY+=("$candidate")

			# Escape special ASCII symbols, including space; allow unicode
			# characters to pass thru unescaped
			candidate=$(printf '%s' "$basename" | sed -E 's/([][{}()<>*?|&^$!~`"\\[:space:]])/\\\1/g')
			COMPREPLY+=("$candidate")
		fi
	done
}

# Attach completion function to `up`
complete -o nospace -F _up up
