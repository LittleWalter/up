<h1>
    <img src="assets/up_folder_icon.svg" alt="Icon representing directory navigation with up script" width="35px">
    Navigate <code>up</code> the Directory Tree with Ease | Bash & Zsh Navigation Script
</h1>

`up` is a Bash and Zsh script that takes the hassle out of navigating parent and ancestor directories. Effortlessly jump multiple levels by index or directory name with autocomplete and regex support. Inspect and dive into directories interactively with [`fzf`](https://junegunn.github.io/fzf/getting-started/)—and optionally track your path history for seamless recall.

Kiss tedious `cd ..` chains goodbye!

## Bash Demo

![vhs animation showing the up script in action](assets/up_vhs_demo_animation.gif "See `up` in action using charmbracelet's `vhs` tool in Bash!")

*`up` animated GIF created programmatically with [`vhs`](https://github.com/charmbracelet/vhs)*

## Zsh Demo

![Manually recorded animation of the up script in action](assets/up_example_use_animation.gif "See `up` in action with a handcrafted screengrab using Zsh!")

*`up` animated GIF created manually with [LICEcap](https://www.cockos.com/licecap/)*

## 📜 Table of Contents
- [Key Features](#-key-features)
- [Installation](#-installation)
    - [Bash](#bash)
    - [Zsh](#zsh)
    - [Man Page (Optional)](#man-page-optional)
- [Configuration](#-configuration)
- [Usage](#-usage)
    - [Jump by Index](#jump-by-index)
    - [Jump to a Directory Name](#jump-to-a-directory-name)
    - [Jump to a Directory Name Using Regex](#jump-to-directory-name-using-regex)
    - [Jump by `fzf`](#jump-by-fzf-fuzzy-finderhttpsgithubcomjunegunnfzf)
    - [Verbose Mode](#verbose-mode)
    - [Navigation to `HOME` and Previous Paths](#navigate-to-home-and-previous-paths)
    - [Output Style Environment Variables](#output-style-environment-variables)
    - [Path History Navigation (Optional)](#path-history-navigation-optional)

## ⭐ Key Features

1. **Multi-Level Navigation**
    - Jump up multiple directory levels by index:
        - `up` (jumps one level)
        - `up 2` (jumps two levels)
        - `up 3` (jumps three levels)

2. **Tab Completion**
    - Autocomplete parent and ancestor directory names with auto-escape (e.g., `\!\[special\ dir\]/`).
    - Supports Unicode directories (e.g., `ダン·メイソン/`, `日本語/`, `привет/`, emojis like `📂/`).

3. **Regex-Based Navigation**
    - Use `-r` for general matches, `-s` for "starts with," `-e` for "ends with," or `-x` for exact matches.
    - Combine with `-i` for case-insensitivity or export `_UP_REGEX_DEFAULT=true` for default regex behavior.

4. **Verbose Feedback**
    - View directory change details with `-v` or enable persistent verbosity with `_UP_ALWAYS_VERBOSE=true`.
    - Customize output colors with style variables or disable them with `_UP_NO_STYLES=true`.

5. **History Features (Optional)**
    - Track recently visited directories by exporting `_UP_ENABLE_HIST=true`.
    - Jump history using `-F` (`fzf`) or the [](#ph-path-history-wrapper-function) wrapper.
        - Use `up_passthru` to capture directory changes from `cd`, [`zoxide`](https://github.com/ajeetdsouza/zoxide), [`jump`](https://github.com/gsamokovarov/jump), etc.
    - List history in order of recency with `-l`.
    - Clear history using `-c`.

6. **Error Handling**
    - Provides proper exit codes and styled error messages (`_UP_ERR_STYLE`) for clarity; useful for scripts or shell prompts like [starship](https://starship.rs/).

7. **Compatibility**
    - Supports both Bash and Zsh, with minimal, standard tool dependencies ensuring fast performance.
    - Optional integration with the fuzzy finder [`fzf`](https://github.com/junegunn/fzf), featuring [`tree`](https://oldmanprogrammer.net/source.php?dir=projects/tree), `ls`, and `stat` previews. (Or [`eza`](https://github.com/eza-community/eza) for `tree` and `ls`, if available.)

---

## ⚙ Installation

### Bash

Download the git repo to your preferred destination. For example:

```sh
git clone https://github.com/LittleWalter/up ~/.local/share/shell/up
```

Add to `.bashrc` or `.bash_profile` on Apple macOS systems:

```bash
source ~/.local/share/shell/up/up.bash # The `up` function
source ~/.local/share/shell/up/up_completion.bash # `up` completion
```

#### Quick Bash Installation

Assuming your Bash config is at `~/.bashrc`, use this snippet to download and append the lines in one step:

```sh
git clone https://github.com/LittleWalter/up ~/.local/share/shell/up
echo 'source ~/.local/share/shell/up/up.bash' >> ~/.bashrc
echo 'source ~/.local/share/shell/up/up_completion.bash' >> ~/.bashrc
```

### Zsh

Download the git repo to your preferred destination. For example:

```sh
git clone https://github.com/LittleWalter/up ~/.local/share/shell/up
```

These scripts are fully compatible with Zsh using `bashcompinit` for seamless integration.

The `autoload` lines enable autocompletion modules.

Add to `.zshrc`:

```bash
autoload -U +X compinit && compinit # Enable Zsh completion 
autoload -U +X bashcompinit && bashcompinit # Enable Bash completion compatibility

source ~/.local/share/shell/up/up.bash # The `up` function
source ~/.local/share/shell/up/up_completion.bash # `up` completion
```

#### Quick Zsh Installation

Assuming your Zsh config is at `~/.zshrc`, use this snippet to download and append the lines in one step:

```sh
git clone https://github.com/LittleWalter/up ~/.local/share/shell/up
echo 'autoload -U +X compinit && compinit' >> ~/.zshrc
echo 'autoload -U +X bashcompinit && bashcompinit' >> ~/.zshrc
echo 'source ~/.local/share/shell/up/up.bash' >> ~/.zshrc
echo 'source ~/.local/share/shell/up/up_completion.bash' >> ~/.zshrc
```

### Man Page (Optional)

The man page for `up` provides detailed usage information that complements the `-h`/`--help` flags and this README. Installing it is optional but recommended for improved command-line documentation.

To install the man page, run the following commands:

```sh
cd ~/.config/shell/up/man         # Navigate to the directory where the scripts are located
chmod +x install_up_man_page.bash # Ensure the script is executable
./install_up_man_page.bash        # Run the installation script
```

After installation, verify that the man page is available by running:

```sh
man up
```

### 📝 Sidenote on `HOME` Directory Organization

Following best practices, I recommend using the [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir-spec/latest/) to reduce `HOME` directory clutter.

By default, `XDG_CONFIG_HOME` is `$HOME/.config` and `XDG_DATA_HOME` is `$HOME/.local/share`. However, these paths might not be explicitly defined in your shell configuration; verify with `echo $XDG_CONFIG_HOME`.

For this project, somewhere within `XDG_DATA_HOME` makes sense.

Within your `.bashrc` or `.zshrc`, or more appropriately `.zshenv`, you may define these as environment variables:

```sh
export XDG_CONFIG_HOME="$HOME/.config" # Configuration files
export XDG_DATA_HOME="$HOME/.local/share" # Persistent data storage
export XDG_CACHE_HOME="$HOME/.cache" # Non-essential files such as shell command history, log files, etc.
```

---

## 🛠️Configuration

`up` offers two straightforward methods to configure environment variables: directly in your shell configuration or through an optional configuration file.

For a complete list of available environment variables and their default values, refer to `up --help` or consult the optional man page.

### **Option 1:** Add to Your Shell Configuration

Define environment variables directly in your shell configuration file (`.bashrc`, `.zshrc`, or `.zshenv`). This approach integrates seamlessly into your existing shell setup:

```bash
export _UP_ERR_STYLE=true
export _UP_HISTFILE=$HOME/.cache/up/up_history.log
export _UP_HISTSIZE=1000
export _UP_ALWAYS_VERBOSE=true
...
```

### **Option 2:** Specify a Configuration File

You can centralize your environment variable definitions in a dedicated configuration file. By default, `up` looks for `~/.config/up/up_settings.conf`. To use a custom path, set the `_UP_CONFIG_FILE` environment variable:

```bash
export _UP_CONFIG_FILE=$HOME/.config/up/my_custom_config.conf
```

#### Configuration File Format

The configuration file uses simple key-value pairs to define environment variables:

```sh
# ╻ ╻┏━┓   ┏━┓┏━╸╺┳╸╺┳╸╻┏┓╻┏━╸┏━┓ ┏━╸┏━┓┏┓╻┏━╸
# ┃ ┃┣━┛   ┗━┓┣╸  ┃  ┃ ┃┃┗┫┃╺┓┗━┓ ┃  ┃ ┃┃┗┫┣╸
# ┗━┛╹  ╺━╸┗━┛┗━╸ ╹  ╹ ╹╹ ╹┗━┛┗━┛╹┗━╸┗━┛╹ ╹╹
# REF: `man up` or `up --help` for info on environent variables

# Genenal Settings
_UP_ALWAYS_VERBOSE=false

# PWD Settings
_UP_ALWAYS_IGNORE_CASE=false
_UP_REGEX_DEFAULT=false
_UP_FZF_PWDOPTS=(
  --height=50%
  --layout=reverse
  --prompt=" Path: "
  --header="󰌑 cd   ^P"
  --preview="eza --color=always --icons --tree {}"
  --bind="ctrl-p:toggle-preview"
  --bind="ctrl-l:change-preview(eza --color=always --icons -laah {})"
  --bind="ctrl-i:change-preview(echo '\`stat\`:'; ustat {})"
  --bind="ctrl-t:change-preview(eza --color=always --icons --tree {})"
  --bind="ctrl-j:preview-page-down,ctrl-k:preview-page-up"
  --preview-window=70%,border-double,top
  --preview-label="[ 󰈍 ^L   ^T   ^I   ^J   ^K ]"
  # Catppuccin Mocha theme
  --color="fg:#c6aad9,hl:#f5a97f"
  --color="fg+:#f4dbd6,bg+:#272935,hl+:#94e2d5"
  --color="info:#a6da95,prompt:#c6a0f6,pointer:#e28b83,marker:#94e2d5,spinner:#f5a97f,header:#e5c890"
)

# History Settings
_UP_ENABLE_HIST=true
_UP_HISTFILE=$XDG_CACHE_HOME/up_history.log
_UP_HISTSIZE=1000
_UP_FZF_HISTOPTS=(
  --height=50%
  --layout=reverse
  --prompt="󰜊 Path: "
  --header="󰌑 cd   ^P  󰮉^D   Missing Paths Omitted"
  --preview="eza --color=always --icons --tree {}"
  --bind="ctrl-p:toggle-preview"
  --bind="ctrl-l:change-preview(eza --color=always --icons -laah {})"
  --bind="ctrl-i:change-preview(echo '\`stat\`:'; ustat {})"
  --bind="ctrl-t:change-preview(eza --color=always --icons --tree {})"
  --bind="ctrl-d:execute(rmd -l {})" # Run custom `rm -rf` script
  --preview-window=hidden
  --bind="ctrl-j:preview-page-down,ctrl-k:preview-page-up"
  --preview-window=70%,border-double,top
  --preview-label="[ 󰈍 ^L   ^T   ^I   ^J   ^K ]"
  --color="header:bright-blue,pointer:bright-magenta"
)

# Style Settings: Catppuccin Mocha theme
_UP_NO_STYLES=false
_UP_DIR_CHANGE_STYLE="\033[38;2;249;226;175m"
_UP_ERR_STYLE="\033[48;2;243;160;168m\033[38;2;30;30;46m"
_UP_PWD_STYLE="\033[38;2;166;227;161m"
_UP_OLDPWD_STYLE="\033[38;2;88;91;112m"
_UP_REGEX_STYLE="\033[38;2;116;199;236m"
```

Environment variables are expanded automatically (e.g., `$HOME` becomes `/home/user`). Variables defined in the shell configuration take precedence over those in the configuration file, allowing flexibility.

---

## ⌨ Usage

![up --help screenshot](assets/up_help_screenshot.jpg "`up --help` has detailed usage information")

### Jump by Index

```sh
$ up <optional: integer>
```

#### Jump 1 Directory

```sh
$ pwd
/Volumes/WD_SSD_1TB/Pictures/wallpapers/apple
$ up
$ pwd
/Volumes/WD_SSD_1TB/Pictures/wallpapers
```

#### Jump 3 Directories

```sh
$ up 3
$ pwd
/Volumes/WD_SSD_1TB
```

### Jump to a Directory Name

#### Display the Autocomplete List

```sh
$ up <tab>
/            Pictures/    Volumes/     WD_SSD_1TB/  wallpapers/
```

#### Autocomplete Directory Name with Prefix

To autocomplete the only directory that starts with `Pic`:

```sh
$ up Pic<tab>
$ up Pictures/
```
### Jump to Directory Name Using Regex

- **`-i` / `--ignore-case`**: Perform case-insensitive regex jumps with the `-s`, `-e`, and `-r` flags.
- **`-s` / `--starts-with`**: Jump to the nearest directory that starts with a given regex pattern.
    - Automatically prefixes your regex with `^` for matching at the start.
- **`-e` / `--ends-with`**: Jump to the nearest directory that ends with a given regex pattern.
    - Appends your regex with `$` for matching at the end.
- **`-r` / `--regex`**: Jump to the nearest directory that matches any part of your regex.
- **`-x` / `--exact`**: Jump to an exact directory name match (default behavior).
    - Useful when `_UP_REGEX_DEFAULT=true` is exported for regex-based navigation by default.

Example: To jump to the closest directory containing `SSD` within `/Volumes/WD_SSD_1TB/Pictures/wallpapers/apple`:

```sh
$ up -r SSD
$ pwd
/Volumes/WD_SSD_1TB
```
Example: To jump to the same location ignoring case:

```sh
$ up -i ssd
$ pwd
/Volumes/WD_SSD_1TB
```

##### Alias Tip

Simplify your workflow by setting up an alias for case-insensitive regex jumps. Add to `.bashrc` or `.zshrc`:

```sh
alias u='up -ri'
```

Once added, you'll only need to type `u <regex>` to leverage case-insensitive regex jumps with the default up behavior intact.

(Use `command -v u` to see if `u` is not already in use.)

#### `_UP_REGEX_DEFAULT` Environment Variable

Prefer regex-based navigation every time without the need for explicit flags? Add the following line to `.bashrc`, `.zshrc`, or `.zshenv`:


```sh
export _UP_REGEX_DEFAULT=true
```

Use the `-x` flag for exact matches to temporarily disable this behavior.

```sh
$ pwd
/Volumes/WD_SSD_1TB/Pictures/wallpapers/apple
$ up -x Volumes
$ pwd
/Volumes
```

### Jump by [`fzf` (Fuzzy Finder)](https://github.com/junegunn/fzf)

Use an optional interactive fuzzy finder to jump directories in your PWD, use the `-f` / `--fzf` flags.

```sh
$ up -f
$ up --fzf
```

#### Customizing `fzf` Options for Ancestor Paths (`PWD`)

When [`eza`](https://github.com/eza-community/eza) is not installed, the default `fzf` options for listing ancestor paths of the current working directory are:

```sh
FZF_PWDOPTS_DEFAULT=(
	--height=50%
	--layout=reverse
	--prompt=" Path: "
	--header="󰌑 cd   ^P"
	--preview="tree -C {}"
	--bind="ctrl-l:change-preview(ls --color=always -lAh {})"
	--bind="ctrl-i:change-preview(echo '\`stat\` Information:'; stat {})"
	--bind="ctrl-t:change-preview(tree -C {})"
	--bind="ctrl-p:toggle-preview"
	--bind="ctrl-j:preview-page-down,ctrl-k:preview-page-up"
	--preview-window=70%,border-double,top
	--preview-label="[ 󰈍 ^L   ^T   ^I   ^J   ^K ]"
)
```
**NOTE**: The [Nerd Fonts](https://github.com/ryanoasis/nerd-fonts) for [icons](https://www.nerdfonts.com/) might not render in this Markdown file.

If `eza` is installed, then the `tree` and `ls` respective equivalents are used for preview for icon support: `eza --color=always --tree --icons {}`, `eza --color=always --icons -laah {}`.

Default `fzf` keybinds:

* `Ctrl-P`: Toggle preview
* `Ctrl-J` / `Ctrl-K`: Preview PGUP/PGDN
* `Ctrl-T`: [`tree`](https://github.com/Old-Man-Programmer/tree) in preview
* `Ctrl-L`: `ls --color=always -lAh` in preview
* `Ctrl-I`: `stat` information in preview

The line `--layout=reverse` will display `fzf` below the prompt line; `--height=50%` uses half of the available terminal emulator window.

##### Example: `fzf` Options for Ancestor Paths (`PWD`)

To customize the display of `fzf`, export `_UP_FZF_PWDOPTS` within `.bashrc`, `.zshrc`, or `.zshenv`.

For example,

```sh
# Define an array of fzf options for PWD
_UP_FZF_PWDOPTS=(
	--height=50%
	--layout=reverse
	--prompt="Select: "
	--preview="ls -A {}"
	--bind="ctrl-p:toggle-preview"
)
export _UP_FZF_PWDOPTS
```

For inspiration, check out this [detailed `fzf` guide](https://thevaluable.dev/practical-guide-fzf-example/).

### Verbose Mode

Just like the `cd` command, `up` will generally not output text upon successful execution.

To display extra information such as `$OLDPWD` and `$PWD` after calling `up`:

```sh
$ up -v [integer or directory name]
$ up --verbose [integer or directory name]
```

#### Verbose Mode Examples

```sh
$ up -v Pictures/
up: jumped 2 dirs to nearest: Pictures
old: /Volumes/WD_SSD_1TB/Pictures/wallpapers/apple
pwd: /Volumes/WD_SSD_1TB/Pictures
```

```sh
$ up verbose 2
up: jumped 2 dirs
old: /Volumes/WD_SSD_1TB/Pictures/wallpapers/apple
pwd: /Volumes/WD_SSD_1TB/Pictures
```

#### `_UP_ALWAYS_VERBOSE` Environment Variable

Prefer verbose mode every time without polluting your aliases? Add the following line to `.bashrc`, `.zshrc`, or `.zshenv`:

```bash
export _UP_ALWAYS_VERBOSE=true
```

### Navigate to `HOME` and Previous Paths

For the sake of completeness, navigating to your `HOME` and previous paths are included.

`HOME` is the only valid full path `up` allows; all other arguments must be a single directory name.

You don't have to be in a `HOME` directory for this to work.

```sh
$ pwd
/Volumes/WD_SSD_1TB/Pictures/wallpapers/apple
$ up ~
$ pwd
/home/mwallace
$ up -
$ pwd
/Volumes/WD_SSD_1TB/Pictures/wallpapers/apple
```

### Output Style Environment Variables

Define output styles to tailor how directory changes, errors, and other terminal messages appear. Setting environment variables allows you to enhance readability and match colors to your terminal theme.

Set ANSI escape sequences in your shell configuration file (i.e., `.bashrc`, `.zshrc`, or `.zshenv`) to avoid editing `up.bash` manually.

* `_UP_DIR_CHANGE_STYLE` for the number of parent directories jumped.
    - Default: Orange (`\033[0;33m`)
* `_UP_ERR_STYLE` for error messages.
    - Default: Red (`\033[0;31m`)
* `_UP_OLDPWD_STYLE` for the previous directory.
    - Default: Light Gray (`\033[0;37m`)
* `_UP_PWD_STYLE` for your current working directory.
    - Default: Light Green (`\033[0;32m`)
* `_UP_REGEX_STYLE` for regular expression patterns, e.g., `'^big_kahuna_.urger$'`.
    - Default: Cyan (`\033[0;36m`)

Default values represent standard ANSI colors, which work reliably across most terminal emulators.

Some terminal emulators may be flexible displaying basic colors and automatically match your preconfigured terminal theme, depending on the capabilities of your terminal emulator (e.g., [WezTerm](https://wezterm.org/) for advanced color support).

Refer to [this GitHub Gist](https://gist.github.com/JBlond/2fea43a3049b38287e5e9cefc87b2124) for more styling ideas.

#### Example: Custom Style Theming

If your terminal emulator supports the full RGB spectrum, you may define style variables using a mix-and-match of foreground (`\033[38;2;<r>;<g>;<b>m`) and background (`\033[48;2;<r>;<g>;<b>m`) colors.

```bash
# `up` style theme: based on Catppuccin Mocha
# REF: https://github.com/catppuccin/catppuccin
# NOTE: ANSI escape format
#       Foreground = "\033[38;2;<r>;<g>;<b>m"
#       Background = "\033[48;2;<r>;<g>;<b>m"
export _UP_DIR_CHANGE_STYLE="\033[38;2;249;226;175m" # Yellow
export _UP_ERR_STYLE="\033[48;2;243;160;168m\033[38;2;30;30;46m" # Red background, "Crust" foreground
export _UP_OLDPWD_STYLE="\033[38;2;88;91;112m" # "Surface2"
export _UP_PWD_STYLE="\033[38;2;166;227;161m" # Green
export _UP_REGEX_STYLE="\033[38;2;116;199;236m" # Sapphire
```
![up example using the Catppuccin Mocha theme for style output](assets/up_catppuccin_mocha_theme_example.jpg "Style example: Catppuccin Mocha theme in WezTerm")

#### Turning Off Styling

To turn off styling and display plaintext only, add the following line to `.bashrc`, `.zshrc`, or `.zshenv`:

```bash
export _UP_NO_STYLES=true
```

### Path History Navigation (Optional)

To track path history with `up`, add to `.bashrc`, `.zshrc`, or `.zshenv`:

```bash
export _UP_ENABLE_HIST=true
```

By default, the path history file is located at `~/.cache/up_history.log` with a maximum size (in lines) of 250.

Export the `_UP_HISTFILE` and `_UP_HISTSIZE` to your preferred path and maximum size in `.bashrc`, `.zshrc`, or `.zshenv`.

```bash
export _UP_HISTFILE="$XDG_CACHE_HOME/up/up_path_history.log"
export _UP_HISTSIZE=1000
```

#### List All History Entries

While the history file is ordered by oldest to newest, path histories are indexed by most recent.

```sh
$ up -l
$ up --list-hist
```

To show the list of most frequently visited paths, use `-L`, `--list-freq` flags:

```sh
$ up -L
$ up --list-freq
```

#### Jump to a Specific History Index

To jump to an index, use the `-j` / `--jump-hist` flags:

```sh
$ up -j 34 # jump to the 34th most recent tracked path
```

#### Show the Current History Size

Display the size of the history with `-S` / `--size`:

```sh
$ up --size
up: history size: [=================...] 88% (221/250)
```

#### Clear and Prune History Entries

Clear history entries with `-c` / `--clear` and passing a timeframe argument in the form `<integer>(min|h|d|m)`, where `min` represents minutes, `h` for hours, `d` for days, and `m` for months.

For example, to remove history entries older than 5 days:

```sh
$ up --clear 5d
up: cleared 31 history entries older than 5d: /home/mrpink/.cache/up_history.log
```

To clear all history, pass no timeframe argument:

```sh
$ up -c
up: history file cleared: /home/mrpink/.cache/up_history.log
```

Prune missing paths in history file with `-p` / `--prune-hist`:

```sh
$ up --prune-hist
up: pruned history: removed 28 invalid paths (24 remaining, max: 250)
```

#### Use `fzf` (Fuzzy Finder) to Inspect and Jump Path History

```sh
$ up -F
$ up --fzf-hist
```

To filter by most recent paths, use `-R`, `--fzf-recent` flags passing `<integer>[min|h|d|m]` argument:

```sh
$ up -R                 # Paths accessed in the last hour
$ up --fzf-recent 15min # Paths accessed in the last 15 minutes
$ up -R 5h              # Paths accessed in the last 5 hours
$ up -R 2d              # Paths accessed in the last 2 days
$ up -R 1m              # Paths accessed in the last month
```

To filter by the most frequently visited paths, use `-m`, `--fzf-freq` flags:

```sh
$ up -m
$ up --fzf-freq
```

##### Customizing `fzf` Options for Paths in History

When [`eza`](https://github.com/eza-community/eza) is not installed, the default `fzf` options for listing historic paths are:

```sh
FZF_HISTOPTS_DEFAULT=(
	--height=50%
	--layout=reverse
	--prompt="󰜊 Path: "
	--header="󰌑 cd   ^P   Missing Paths Omitted"
	--preview-window=hidden
	--preview="tree -C {}"
	--bind="ctrl-l:change-preview(ls --color=always -lAh {})"
	--bind="ctrl-t:change-preview(tree -C {})"
	--bind="ctrl-i:change-preview(echo '\`stat\` Information:'; stat {})"
	--bind="ctrl-p:toggle-preview"
	--bind="ctrl-j:preview-page-down,ctrl-k:preview-page-up"
	--preview-window=70%,border-double,top
	--preview-label="[ 󰈍 ^L   ^T   ^I   ^J   ^K ]"
)
```

The preview window is hidden by default; `Ctrl-P` to toggle the preview window.

In the header, "Missing Paths Omitted" denotes non-jumpable paths in history are skipped.

##### Example: `fzf` Options for Paths in History

To customize the display of `fzf`, export `_UP_FZF_HISTOPTS` within `.bashrc`, `.zshrc`, or `.zshenv`.

```sh
# Example: Define array-based fzf options w/ `ls -A` preview
_UP_FZF_HISTOPTS=(
    --height=50%
    --layout=reverse
    --prompt="Select: "
    --preview="ls -A {}"
    --bind="ctrl-p:toggle-preview"
)
export _UP_FZF_HISTOPTS
```

#### `up` Wrapper Functions

To access the following wrapper functions, set the `_UP_ENABLE_HIST` environment variable within `.bashrc`, `.zshrc`, or `.zshenv`:

```bash
export _UP_ENABLE_HIST=true
```

##### `up_passthru` Helper Function

By default, `up` only tracks its own path history when `_UP_ENABLE_HIST=true` is exported.

To capture and track global path histories, use the `up_passthru` helper function by adding aliases to `.bashrc` and `.zshrc`.

```bash
# up: Global history logging 
alias cd='up_passthru cd' # cd: Use `builtin cd -- <path>` to a skip logging
alias z='up_passthru z'   # zoxide
```

##### `ph` (Path History) Wrapper Function

`ph` is a wrapper for `up` that focuses on path history navigation.

If you are tracking path history of `cd`, `zoxide`, `jump`, etc., using `up_passthru`, this is a more intuitive interface.

![ph --help screenshot](assets/ph_help_screenshot.jpg "`ph --help` is an `up` wrapper for path history")
