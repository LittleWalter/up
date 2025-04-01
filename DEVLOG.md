# DEVLOG

Development-related notes, not really a CHANGELOG.

## Motivation & Goals

The goal of this project is to deepen my understanding of shell scripting, specifically Bash and Zsh, by building something useful. While I recognize there are excellent existing solutions for directory navigation, this project serves as a creative opportunity to experiment and learn.

Maybe I'll get around to learning POSIX-compliant scripting for portability later.

## Table of Contents

- [Motivation & Goals](#motivation--goals)
- [March 2025](#march-2025)
- [Known Issues](#-known-issues)
- [TODOs and Future Ideas](#-todos-and-future-ideas)
- [Credits](#credits)

## March 2025

### __[2025-03-31]__
* __Fixes:__ Verbose flag handling for wrapper function `ph -v`.
* __Refactoring:__ Minor changes to `up-completion.bash`.
* __Documentation:__
  - Added `ph -help` screenshot to `README.md`.
  - Moved contributing section in `README.md` to `CONTRIBUTING.md`.

### __[2025-03-30]__
* __Features:__
  * History features must be enabled by setting `export _UP_ENABLE_HIST=true` in shell config.
    - Display message when history-related flags used and history not enabled.
  * Added `-H` / `--hist-status` flags to check whether history logging is on/off.
* __Changes:__ `up::filter_history_with_fzf` omits missing/deleted paths; only valid paths listed by `fzf`.

### __[2025-03-29]__
* __Documentation:__ Fixed typos and inaccuracies.
* __Fixes:__ Added rudimentary file locking code for writing path history; possible race conditions on multiple shell instances.
* __Refactor:__
  - `up::construct_dotted_path`:
    - Swapped for loop to `printf "../%.0s" $(seq 1 "$jump_index")`.
    - Check to see if the passed index value is not larger than possible for `PWD`.
  - `if $verbose_mode; ...` -> `if [[ "$verbose_mode" == true ]] ...` for Boolean checks (best practice).
* __Features:__
  - Added `up::filter_ancestors_with_fzf` (`-f` / `--fzf`) to jump to ancestor paths within `PWD` only.
  - `_UP_FZF_HISTOPTS`: Environment variable for setting `fzf` options for path history.
  - `_UP_FZF_PWDOPTS`: Environment variable for setting `fzf` options for `PWD`.
* __Changes:__ `up::filter_history_with_fzf` now uses `-F` / `--fzf-hist` flags.

### __[2025-03-28]__
* __Features:__
  - `ph` (path history): Added convenience function for printing and jumping history log.
  - Added `up::print_history_size` to show current size/percent in history log.
  - Added `fzf` preview toggle for `-f` / `--fzf`, `^P` to toggle; PGDN/PGUP in preview window `^J` / `^K`.
* __Documentation:__
  - Help `-h` / `--help` flags display information for `ph`, `up_passthru`
  - More general verbiage polishing in help output.
  - Moved TODOs and Known Issues sections to this `DEVLOG.md` file.
  - Updated help screenshot.
* __Fixes:__ `return` statements now returning numeric values, forgot to prefix variables with `$`—this is not C! 🙈

### __[2025-03-27]__
* __Documentation:__
  - Corrected directory terminology within the project; removed words "subdirectory" and "subdirectories".
    - The proper terminology is "parent", "ancestor", and "directory".
  - Added examples section for `up --help` output; simplified usage section.
* __Changes:__ Updated tab completion script to check for `sed` access, along with some minor refactoring.
  - Now using the previous character-escaping code as a fallback. However, this code will only properly escape ASCII directory names, losing Unicode support.
* __Refactor:__ Using `local -r` where possible for immutable variables.
* __Features:__ Started writing code for history log file. New flags and environment variables:
  - `-l` / `--list-hist`: List the content of history log file.
  - `-j` / `--jump-hist`: Jump to path in history by most recent index, i.e, `1` is the previous, etc.
  - `-f` / `--fzf`: Supports fuzzy search if user has `fzf` installed; drop down menu appears below command prompt.
  - `-c` / `--clear`: Clears all history in log file.
  - `_UP_HISTFILE`: Environment variable for the path of the history log file, default: ~/.cache/up_history.zsh`
  - `_UP_HISTSIZE`: Environment variable for the maximum number of history entries, i.e., the number of lines in the log file.
  - `up_passthru`: Function to use with aliases to track directory changes universally in the shell.
    - `alias cd='up_passthru cd'` for shell buitin `cd` support.
    - `alias z='up_passthru z'` for [zoxide](https://github.com/ajeetdsouza/zoxide) support.
* __Fixes:__ Removed `return` from `up::num_of_dirs_changed`; now a call to "return" `echo` instead.
  - `return` only handles unsigned 8-bit integers.

### __[2025-03-26]__
* __Features:__ Added support for regular expressions. Need to add tests.
  - Added `-r` / `--regex`, `-s` / `--starts-with`, `-e` / `--ends-with`, and `-i` / `--ignore-case` flags.
* __Features:__ Added `_UP_REGEX_STYLE`, `_UP_REGEX_DEFAULT`, `_UP_ALWAY_IGNORE_CASE` environment varibles for regex support.
* __Changes:__ Removed naked (non-tack) flags. All flags must have one or two dashes.

### __[2025-03-23]__
* Committed initial version of project to GitHub.

## 🐞 Known Issues

There may be skill-related limitations: I’m not a Bash scripting expert.

* No color support for tab completion list
    * I could not get Zsh to use `LS_COLORS` via `zstyle` settings.
* Tab completion list not in order of `PWD`
    * There’s no guarantee of the completion list order.

## ✅ TODOs and 💡Future Ideas

### TODOs

### March 2025

- [ ] Add pager environment variable.
- [ ] Clean and refactor `up.bash` to make it more readable and maintainable.
- [ ] Add `bats` tests for `up.bash` related to:
    - [ ] Regex flags
    - [ ] History tracking and navigation
- [ ] Add more styling examples in `README.md`, e.g., Dracula, gruvbox.

### Ideas

### March 2025

- [ ] Write a fish-compatible version.
  * I'm not using [fish](https://fishshell.com/) as my primary shell.
- [ ] Write a binary version of `up.bash` in a language like Go or Rust for universal shell compatibility. (Better idea than this script?)
  * Only completion scripts for target shells would need to be created.
- [ ] History session management.
- [ ] Bookmarking paths.

## 🍿Credits

Thanks to the original script writers and public shell configs!

### [Derek Taylor's Dotfiles (dwt1 on GitLab)](https://gitlab.com/dwt1/dotfiles)

Originally, I used Derek Taylor's `up` function unmodified within his [`.zshrc`](https://gitlab.com/dwt1/dotfiles/-/blob/master/.zshrc?ref_type=heads):

```bash
up () {
  local d=""
  local limit="$1"

  # Default to limit of 1
  if [ -z "$limit" ] || [ "$limit" -le 0 ]; then
    limit=1
  fi

  for ((i=1;i<=limit;i++)); do
    d="../$d"
  done

  # perform cd. Show error if cd fails
  if ! cd "$d"; then
    echo "Couldn't go up $limit dirs.";
  fi
}
```

This minimalist function works well for navigating up by the number of directories.

### [Oliver Weiler's `up` Bash Scripts (helpermethod on GitHub)](https://github.com/helpermethod/up)

I later found [this simple `up` Bash script](https://github.com/helpermethod/up/blob/main/up) to navigate by directory name, complete with tab completion and [bats](https://bats-core.readthedocs.io/en/stable/index.html) scripts. 

```bash
up() {
  (($# == 0)) && cd .. && return
  [[ $1 == / ]] && cd / && return

  # shellcheck disable=SC2164
  cd "${PWD%"${PWD##*/"$1"/}"}"
}
```

My modifications are a result of combining the functionalities of these two `up` functions. 


### [Jonathan Suh's Terminal Colors for Bash (jonsuh on GitHub)](https://gist.github.com/jonsuh/3c89c004888dfc7352be)

Instead of writing ANSI escape codes manually, use this simple list of 15 colors and a reset value in your shell config.
