# DEVLOG

## Table of Contents

- [March 2025](#march-2025)
- [TODOs and Future Ideas](#-todos-and-future-ideas)
- [Known Issues](#-known-issues)

## March 2025

### [2025-03-28]
* __Features:__
  - `ph` (path history): Added convenience function for printing and jumping history log.
  - Added `up::print_history_size` to show current size/percent in history log.
  - Added `fzf` preview toggle for `-f` / `--fzf`, `^P` to toggle; PGDN/PGUP in preview window `^J` / `^K`.
* __Documentation__:
  - Help `-h` / `--help` flags display information for `ph`, `up_passthru`
  - More general verbiage polishing in help output.
  - Moved TODOs and Known Issues sections to this `DEVLOG.md` file.
  - Updated help screenshot.
* __Fix:__: `return` statements now returning numeric values, forgot to prefix variables with `$`—this is not C! 🙈

### [2025-03-27]
* __Documentation:__
  - Corrected directory terminology within the project; removed words "subdirectory" and "subdirectories".
    - The proper terminology is "parent", "ancestor", and "directory".
  - Added examples section for `up --help` output; simplified usage section.
* __Change:__ Updated tab completion script to check for `sed` access, along with some minor refactoring.
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
* __Fix:__ Removed `return` from `up::num_of_dirs_changed`; now a call to "return" `echo` instead.
  - `return` only handles unsigned 8-bit integers.

### [2025-03-26]
* __Features:__ Added support for regular expressions. Need to add tests.
  - Added `-r` / `--regex`, `-s` / `--starts-with`, `-e` / `--ends-with`, and `-i` / `--ignore-case` flags.
* __Features:__ Added `_UP_REGEX_STYLE`, `_UP_REGEX_DEFAULT`, `_UP_ALWAY_IGNORE_CASE` environment varibles for regex support.
* __Change:__ Removed naked (non-tack) flags. All flags must have one or two dashes.

### [2025-03-23]
* Committed initial version of project to GitHub.

## ✅ TODOs and 💡Future Ideas

Possible ideas to work on.

- [x] Refactor `up.bash` to make it more readable and maintainable.
  * More refinements later.
- [ ] Add `bats` tests for `up.bash` related to regex flags.
- [ ] Add more styling examples in this `README.md`, e.g., Dracula, gruvbox.
- [ ] Write a fish-compatible version.
  * I'm not using [fish](https://fishshell.com/) as my primary shell.
- [ ] Write a binary version of `up.bash` in a language like Go or Rust for universal shell compatibility. (Better idea?)
  * Only completion scripts for target shells would need to be created.

## 🐞 Known Issues

There may be skill-related limitations: I’m not a Bash scripting expert.

* No color support for tab completion list
    * I could not get Zsh to use `LS_COLORS` via `zstyle` settings.
* Tab completion list not in order of `PWD`
    * There’s no guarantee of the completion list order.
