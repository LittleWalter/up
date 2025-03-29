<h1>
    <img src="assets/up_folder_icon.svg" alt="Icon representing directory navigation with up script" width="35px">
    Navigate <code>up</code> the Directory Tree with Ease | Bash & Zsh Navigation Script
</h1>

`up` is a Bash and Zsh script that takes the hassle out of navigating to parent and ancestor directories. Effortlessly jump multiple levels, autocomplete directory names, or harness powerful regex-based matching for precise and flexible navigation—all in a single, intuitive command!

Easily handle:
- **Tab Completion**: Quickly autocomplete directory names.
- **Regex Patterns**: Jump to directories that start, end, or partially match your search, with options for case-insensitive matching.
- **Unicode Paths**: Works with directories containing non-Latin characters like `フォルダ/`, `🚀/`, `नमस्ते/`, or `مرحبا/`.

Kiss tedious `cd ..` chains goodbye!

![Animation showing the up script in action](assets/up_example_use_animation.gif "See `up` in action!")

## 📜 Table of Contents
- [Key Features](#-key-features)
- [Installation](#-installation)
- [Usage](#-usage)
- [Testing](#-testing-in-bats-bash-automated-testing-system)
- [Contributing](#-contributing)
- [Credits](#credits)

## ⭐ Key Features

1. **Simple Multi-Level Navigation**:
    - Jump up multiple directory levels by index:
        - `up` (jumps one level)
        - `up 2` (jumps two levels)
        - `up 3` (jumps three levels)

2. **Intuitive Tab Completion**:
    - Autocomplete parent and ancestor directory names with auto-escape (e.g., `\!\[special\ dir\]/`).
    - Supports Unicode directories (e.g., `ダン·メイソン/`, `日本語/`, `привет/`, emojis like `📂/`).

3. **Regex-Based Navigation**
    - Use `-r` for general matches, `-s` for "starts with," `-e` for "ends with," or `-x` for exact matches.
    - Combine with `-i` for case-insensitivity or export `_UP_REGEX_DEFAULT=true` for default regex behavior.

4. **Detailed Feedback**
    - View directory change details with `-v` or enable persistent verbosity with `_UP_ALWAYS_VERBOSE=true`.
    - Customize output colors with style variables or disable them with `_UP_NO_STYLES=true`.

5. **History Features**
    - Track recently visited directories and jump to them using `ph` or `-f` (`fzf`).
        - Use `up_passthru` to capture directory changes from `cd`, `zoxide`, `jump`, etc.
    - List history in order of recency with `-l`.
    - Clear history entirely using `-c`.

6. **Error Handling**:
    - Provides proper exit codes and styled error messages (`_UP_ERR_STYLE`) for clarity; useful for scripts or shell prompts like [starship](https://starship.rs/).

7. **Compatibility**
    - Works with Bash and Zsh. Minimal dependencies for fast performance.
    - Optional fuzzy finder integration via [`fzf`](https://github.com/junegunn/fzf) with a [`tree`](https://oldmanprogrammer.net/source.php?dir=projects/tree) preview.

## ⚙ Installation

### Bash

Download the git repo to your preferred destination. For example:

```sh
git clone https://github.com/LittleWalter/up ~/.local/share/shell/up
```

Add to `.bashrc` or `.bash_profile` on Apple macOS systems:

```bash
source ~/.local/share/shell/up/up.bash # The `up` function
source ~/.local/share/shell/up/up-completion.bash # `up` completion
```

#### Quick Bash Installation

Assuming your Bash config is at `~/.bashrc`, use this snippet to download and append the lines in one step:

```sh
git clone https://github.com/LittleWalter/up ~/.local/share/shell/up
echo 'source ~/.local/share/shell/up/up.bash' >> ~/.bashrc
echo 'source ~/.local/share/shell/up/up-completion.bash' >> ~/.bashrc
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
source ~/.local/share/shell/up/up-completion.bash # `up` completion
```

#### Quick Zsh Installation

Assuming your Zsh config is at `~/.zshrc`, use this snippet to download and append the lines in one step:

```sh
git clone https://github.com/LittleWalter/up ~/.local/share/zsh/up
echo 'autoload -U +X compinit && compinit' >> ~/.zshrc
echo 'autoload -U +X bashcompinit && bashcompinit' >> ~/.zshrc
echo 'source ~/.local/share/shell/up/up.bash' >> ~/.zshrc
echo 'source ~/.local/share/shell/up/up-completion.bash' >> ~/.zshrc
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

## ⌨ Usage

For example usage, assume `pwd` command returns:

```sh
$ pwd
/Volumes/WD_SSD_1TB/Pictures/wallpapers/apple
```

### Jump to the nth Ancestor Directory

```sh
$ up <optional: integer>
```

#### Jump 1 Directory

To simple jump to the parent directory:

```sh
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
#### Jump to a Directory Name with Regex

Leverage regular expression flags for flexible directory navigation:

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
$ up -ri ssd
$ pwd
/Volumes/WD_SSD_1TB
```

##### Alias Tip

Simplify your workflow by setting up an alias for case-insensitive regex jumps. Add this line to your `.bashrc` or `.zshrc` to enable it:

```sh
alias u='up -ri'
```

Once added, you'll only need to type `u <regex>` to leverage case-insensitive regex jumps with the default up behavior intact.

(Use `command -v u` to see if `u` is not already in use.)

#### `_UP_REGEX_DEFAULT` Environment Variable

Prefer regex-based navigation every time without the need for explicit flags? Add the following line to your `.bashrc`, `.zshrc`, or `.zshenv`:


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

### Display Help

![up --help screenshot](assets/up_help_screenshot.jpg "`up --help` has detailed usage information")

```sh
$ up -h
$ up --help
```

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

Prefer verbose mode every time without polluting your aliases? Add the following line to your `.bashrc`, `.zshrc`, or `.zshenv`:

```bash
export _UP_ALWAYS_VERBOSE=true
```

### Navigate to `HOME` Path

For the sake of completeness, navigating to your `HOME` path is included.

`HOME` is the only valid full path `up` allows; all other arguments must be a single directory name.

You don't have to be in a `HOME` directory for this to work.

```sh
$ up ~
$ up $HOME
$ up /home/mwallace # Unix-like example
$ up /Users/vvega   # macOS example
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

To turn off styling and display plaintext only, add the following line to your `.bashrc`, `.zshrc`, or `.zshenv`:

```bash
export _UP_NO_STYLES=true
```

## 🔬 Testing in Bats (Bash Automated Testing System)

Tests are written for [`bats-core`](https://github.com/bats-core/bats-core), a test framework for Bash.

Tested with **Bash 3.2.57(1)-release** and **Zsh 5.9**.

Refer to the [official documentation of Bats](https://bats-core.readthedocs.io/en/stable/installation.html) for installation information.

###  Homebrew Installation

Cheers to easy installation methods! 🍺

```sh
$ brew install bats-core
```

### Running Tests

```sh
$ bats up_test.bats # Test the `up` function
$ bats up-completion_test.bats # Test the `_up` function for Bash completions
```

## 🤝 Contributing

Contributions and suggestions are welcome!

If you’d like to contribute:
1. Fork the repository.
2. Make your changes in a feature branch.
3. Open a pull request with your proposed changes.

For major changes, please open an issue to discuss what you’d like to improve.

Before submitting a pull request, please:
- Run the tests with `bats` to ensure everything works as expected.

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

It's also just another excuse to fiddle with my Zsh config and do some light Bash scripting. ☺️

### [Jonathan Suh's Terminal Colors for Bash (jonsuh on GitHub)](https://gist.github.com/jonsuh/3c89c004888dfc7352be)

Instead of writing ANSI escape codes manually, use this simple list of 15 colors and a reset value in your shell config.
