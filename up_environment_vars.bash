# ╻ ╻┏━┓   ┏━╸┏┓╻╻ ╻╻┏━┓┏━┓┏┓╻┏┳┓┏━╸┏┓╻╺┳╸   ╻ ╻┏━┓┏━┓┏━┓ ┏┓ ┏━┓┏━┓╻ ╻
# ┃ ┃┣━┛   ┣╸ ┃┗┫┃┏┛┃┣┳┛┃ ┃┃┗┫┃┃┃┣╸ ┃┗┫ ┃    ┃┏┛┣━┫┣┳┛┗━┓ ┣┻┓┣━┫┗━┓┣━┫
# ┗━┛╹  ╺━╸┗━╸╹ ╹┗┛ ╹╹┗╸┗━┛╹ ╹╹ ╹┗━╸╹ ╹ ╹ ╺━╸┗┛ ╹ ╹╹┗╸┗━┛╹┗━┛╹ ╹┗━┛╹ ╹
# Constant definitions used by `up` including those defined by
# environment variables, plus related helper functions.

# Assign empty string to all styling constants
up::reset_styling() {
	BOLD=""
	UNDERLINE=""
	LABEL_STYLE=""
	DIR_CHANGE_STYLE=""
	ERR_STYLE=""
	OLDPWD_STYLE=""
	PWD_STYLE=""
	REGEX_STYLE=""
	RESET=""
}

# Initialize fzf options:
# Ctrl-P toggles preview; Ctrl-J/Ctrl-K PGDN/PGUP in preview
# Ctrl-L displays `ls` as a long list, in human-readable sizes, and in color
# Ctrl-T displays dir tree in color (dependency: might need to install `tree` or `eza`)
# Ctrl-I displays `stat` information in preview
up::initialize_fzf_options() {
	local tree_option="tree -C {}"
	local ls_option="ls --color=always -lAh {}"
	local stat_option="echo '\`stat\`:'; stat {}"

	# Check for `eza` availability
	if up::is_command_available "eza"; then
		tree_option="eza --color=always --tree --icons {}"
		ls_option="eza --color=always --icons -laah {}"
	fi

	# Check for Rust-based `ustat` availability
  # NOTE: Added in case there's a GNU coreutils vs. uutils-coreutils linking conflict in
  # Homebrew, etc. The one-line BSD version of `stat` is harder to read.
	if up::is_command_available "ustat"; then
		stat_option="echo '\`stat\`:'; ustat {}"
	elif up::is_command_available "gstat"; then
		stat_option="echo '\`stat\`:'; gstat {}" # GNU coreutils are prefixed with "g" when using brew
	fi

	# Initialize default FZF options for history and PWD
	FZF_HISTOPTS_DEFAULT=(
		--height=50%
		--layout=reverse
		--prompt="󰜊 Path: "
		--header="󰌑 cd   ^P   Missing Paths Omitted"
		--preview-window=hidden
		--preview="$tree_option"
		--bind="ctrl-l:change-preview($ls_option)"
		--bind="ctrl-t:change-preview($tree_option)"
		--bind="ctrl-i:change-preview($stat_option)"
		--bind="ctrl-p:toggle-preview"
		--bind="ctrl-j:preview-page-down,ctrl-k:preview-page-up"
		--preview-window=70%,border-double,top
		--preview-label="[ 󰈍 ^L   ^T   ^I   ^J   ^K ]"
	)

	FZF_PWDOPTS_DEFAULT=(
		--height=50%
		--layout=reverse
		--prompt=" Path: "
		--header="󰌑 cd   ^P"
		--preview="$tree_option"
		--bind="ctrl-l:change-preview($ls_option)"
		--bind="ctrl-t:change-preview($tree_option)"
		--bind="ctrl-i:change-preview($stat_option)"
		--bind="ctrl-p:toggle-preview"
		--bind="ctrl-j:preview-page-down,ctrl-k:preview-page-up"
		--preview-window=70%,border-double,top
		--preview-label="[ 󰈍 ^L   ^T   ^I   ^J   ^K ]"
	)

	# Override with user-defined environment options if set
	FZF_HISTOPTS=("${_UP_FZF_HISTOPTS[@]:-${FZF_HISTOPTS_DEFAULT[@]}}")
	FZF_PWDOPTS=("${_UP_FZF_PWDOPTS[@]:-${FZF_PWDOPTS_DEFAULT[@]}}")
}

### Constant definitions: Avoid magic values! ##########################

VERSION="1.0.0"

EXIT_SUCCESS=0
EXIT_FAILURE=1

LOG_FILE="${_UP_HISTFILE:-${XDG_CACHE_HOME:-$HOME/.cache}/up_history.log}"

HIST_ENABLED=${_UP_ENABLE_HIST:-false}

# Create the log file if it doesn't exist
if [[ ! -f "$LOG_FILE" ]] && [[ "$HIST_ENABLED" == true ]]; then
	mkdir -p "$(dirname "$LOG_FILE")"  # Create the directory if it doesn't exist
	touch "$LOG_FILE"
fi

LOG_SIZE_DEFAULT=250
LOG_SIZE=${_UP_HISTSIZE:-$LOG_SIZE_DEFAULT}

# `fzf` (interactive fuzzy finder)
up::initialize_fzf_options

# Set styling constants: colors displayed for `up`, mostly for verbose mode
if [[ "${_UP_NO_STYLES:-false}" == true ]]; then
	up::reset_styling
else
	# REF: For fallback color definitions see https://gist.github.com/jonsuh/3c89c004888dfc7352be
	BOLD="\033[1m"
	UNDERLINE="\033[4m"
	LABEL_STYLE="${BOLD}${UNDERLINE}"
	DIR_CHANGE_STYLE="${_UP_DIR_CHANGE_STYLE:-${ORANGE:-\033[0;33m}}"
	ERR_STYLE="${_UP_ERR_STYLE:-${RED:-\033[0;31m}}"
	OLDPWD_STYLE="${_UP_OLDPWD_STYLE:-${LIGHTGRAY:-\033[1;37m}}"
	PWD_STYLE="${_UP_PWD_STYLE:-${LIGHTGREEN:-\033[0;32m}}"
	REGEX_STYLE="${_UP_REGEX_STYLE:-${CYAN:-\033[0;36m}}"
	RESET="\033[0m"
fi

# Error exit code constants
ERR_BAD_ARG=2     # invalid argument passed
ERR_ACCESS=127    # inaccessible directory or `cd` or other command
ERR_NO_CHANGE=3   # no directory change

# Verbose mode constants
VERBOSE_TWO_LINES=2
VERBOSE_DEFAULT=3

# Match type constants: for named dirs
MATCH_EXACT=1
MATCH_REGEX=2
MATCH_START=3
MATCH_END=4

# Flag processing constants for non-default behavior (0 or 1 args)
FLAG_DEFAULT=0
HIST_JUMP=1
HIST_FZF=2
PWD_FZF=3
