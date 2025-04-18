# DEVLOG

Development-related notes, not really a CHANGELOG.

## Motivation & Goals

The goal of this project is to deepen my understanding of shell scripting, specifically Bash and Zsh, by building something useful. While I recognize there are excellent existing solutions for directory navigation, this project serves as a creative opportunity to experiment and learn.

Maybe I'll get around to learning POSIX-compliant scripting for portability later.

## Table of Contents

- [Motivation & Goals](#motivation--goals)
- [April 2025](#april-2025)
- [March 2025](#march-2025)
- [Known Issues](#-known-issues)
- [TODOs and Future Ideas](#-todos-and-future-ideas)
- [Credits](#credits)

## April 2025

### __[2025-04-17]__

* __Features:__ `_UP_EXCLUDED_PATHS` environment variable that defines an array of exact paths to exclude from history log.
* __Other:__ Feature complete, minus minor changes such as adding `_UP_PAGER` environment variable.

### __[2025-04-14]__

* __Refactoring:__ Changed sub-function names from `up::` and `_up::` to `_up::` and `__up::` to obscure from Bash completion. `_up::` denotes sub-functions for `up` and `__up::` for `_up` tab completion.
* __Changes:__
    - Hiding sub-functions from Zsh autocompletion with `zstyle ':completion:*' ignored-patterns '_up::*|__up::*'. Could not figure out how to do the same with Bash.
    - Skipping tab completion for most flags such as `-h`, `-f`, `--list-hist`, etc.
* __Features:__ Added verbose mode output to `-c`/`--clear` to display and confirm history removal. Note: The verbose flag must be passed before the clear flag for this to work, e.g., `up -vc 1d`.

### __[2025-04-13]__

* __Fixes:__
    - Tab completion properly escapes multiple whitespace characters in a row, e.g., `a dir_name  2 spaces` should be `a\ dir_name\ \2\ spaces/`. Directory names with more than one space were collapsed.
    - Properly handle paths with multiple whitespace characters in a row for `-m`/`--fzf-freq`, `-F`/`--fzf-hist`, and `-R`/`--fzf-recent` flags, i.e., options using `fzf`. Paths with spaces were not being shown; mostly incorrect `awk` invocations.
* __Changes:__
    - Added header and history line numbers of removed paths for verbose mode output with the `-p`/`--prune` flag.
    - Generalized `up::pluralize_dir` to `up::pluralize`; moved from `up.bash` to `up_lib/up_utils.bash`.

### __[2025-04-12]__

* __Fixes:__
    - Changed `awk '{print $3}' "$LOG_FILE"` to `awk '{print substr($0, index($0, $3))}'` in `up::print_paths_by_frequency` and `up::filter_most_frequent_paths` within `up_history.bash`. `{print $3}` truncates path names with whitespace.
    - Changed `awk '{print $3 " " $4 " " $5}')` to `cut -d' ' -f3-` to avoid truncating path names with whitespace in `up::jump_from_history` within `up_history.bash`.
* __Documentation:__ Fixed improperly escaped characters of examples of `fzf` options in man page.
* __Features:__ Added verbose mode output to `-p`/`--prune` showing removed paths. Note: The verbose flag must be passed before the prune flag for this to work, e.g. `up -vp`.

### __[2025-04-11]__

* __Documentation:__
    - Added dynamic check for config file in `-h` / `--help` output.
    - Fixed minor errors in man page.

### __[2025-04-10]__

* __Fixes:__ Parsing comments in arrays (`up::load_config_file`).

### __[2025-04-09]__

* __Fixes:__ Updated all instances of `cd` in `up.bash` and `up_lib/up_history.bash` to use `cd --`, ensuring compatibility with directory names that begin with a hyphen (e.g., `-exampleDir`). This change is now documented under the EDGE CASES subsection within the EXAMPLES section of the man page.
* __Features:__ Introduced support for a centralized configuration file to define environment variables in one location.
    - `_UP_CONFIG_FILE`: A new environment variable allowing users to specify a custom path to the configuration file (default: `~/.config/up/up_settings.conf`).
    - To avoid external parsers such as `tomlq`, the configuration file format defines environment variables using simple key-value pairs, such as:
      ```bash
      _UP_ENVIRONMENT_VARIABLE_NAME=value
      ```

### __[2025-04-08]__

* __Changes:__ Set `-i` / `--ignore-case` flag to use standard regex matching (`-r`) when not combined with other regex flags. It used to require explicit use of other regex flags.
* __Documentation:__ More additions and refinements to man page.

### __[2025-04-07]__

* __Documentation:__
  - Created `up.1` man page in `groff` derived from the `--help` output and available Markdown.
    - README for `man` page installation instructions.
    - The simple `install_up_man_page.bash` script automates installation of the manual.
* __Features:__ Modified the `-c` / `--clear` function to take `<integer>(min|h|d|m)` argument.

### __[2025-04-06]__
* __Refactoring:__ Modularized pagination code from `up::show_history` into `up::run_with_pagination`.
* __Features:__
    - `L` / `--list-freq` flags display the history sorted by frequency of paths visited.
    - `m` / `--fzf-freq` opens `fzf` with the most frequently visited list, sorted by most to least visited; only displays existing paths.

### __[2025-04-05]__
* __Refactoring:__ Path history functions only sourced when `_UP_ENABLE_HIST=true`. `up.bash` history flags displays message when using and logging disabled.

### __[2025-04-04]__
* __Features:__ Added `-R`, `--fzf-recent` to open `fzf` for recent paths by `<integer>[min|h|d|m]` for timeframes representing hours, days, and months.
* __Documentation:__
  - Updated `-h` / `--help` text by organizing flags by sections "PWD Navigation" and "Path History Management".

### __[2025-04-02]__
* __Refactoring:__
  - Modularized monolithic `up.bash` into multiple files (1200+ raw lines).
    - `up_lib/up_environment_vars.bash`: Definitions of constants defined by environment variables, etc.
    - `up_lib/up_wrappers.bash`: Definitions of wrapper functions such as `ph` and `up_passthru`.
    - `up_lib/up_history.bash`: Definitions of path history functions.
    - `up_lib/up_utils.bash`: Definitions of miscellanous helper functions.
  - Moved `bats` test files into `tests/` directory.
  - _Linting_: Turned on Bash LSP support for Neovim by using [`bash-language-server`](https://github.com/bash-lsp/bash-language-server) and [`shellcheck`](https://www.shellcheck.net/); fixing basic mistakes and closing most warnings, e.g., missing quotes, etc.
* __Changes:__ Added checks for `ustat` and `gstat` for `fzf` options defaults; the macOS BSD version of `stat` is harder to visually parse.
* __Features:__ Added `-p` / `--prune-hist` to remove dead paths in history file.

### __[2025-04-01]__
* __Fixes:__ Flag processing behavior for `up` and `ph` on arbitrary combinations of flag ordering. Issues around flags that should not immediately return an exit value such as `fzf`-related commands.
* __Documentation:__ Added programmatic [`vhs`](https://github.com/charmbracelet/vhs) animated demo source code at `assets/up_vhs_demo.tape`; the file is `asset/up_vhs_demo_animation.gif`.
* __Changes:__ Dynamically check for `eza` installation for use with `fzf`; default to `ls` and `tree` when not available.

## March 2025

Regular commits to main branch.

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
