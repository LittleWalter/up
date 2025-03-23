<h1>
    <img src="assets/up_folder_icon.svg" alt="up folder icon" width="35px">
    Navigate <code>up</code> the directory tree with ease!
</h1>

`cd` is great for drilling down the directory tree with tab completion, but not as convenient going directly up.

We all know it can be a pain to use regularly use `cd ..` commands.

These Bash scripts offer a quick, flexible, and simple way to go up the directory tree of your current working directory. 

Use the `up` function instead!

![up example use animation](assets/up_example_use_animation.gif)

## ⭐️ Notable Features

1. Navigate up your current working directory by:
    * Number of subdirectories, e.g., `up 2` jumps two levels, `up 3` to jumps three levels, etc.
    * Subdirectory name with Unicode support, e.g., Japanese, Cyrillic, emojis, etc.
2. Tab completion of subdirectory names
    * Auto-escaping special ASCII characters like space, `*`, `[`, `!`, etc.
3. Verbose mode to display detailed directory change information
    * Basic color output of `PWD`, number of dirs changed, and errors
4. Robust exit status handling on errors 
    * Useful for shell configurations that utilize exit codes like the [starship](https://starship.rs/) prompt 
5. Covers edge cases; always use a trailing slash (`/`) to distinguish directory arguments
    * Subdirectories with all-integers names such as `2/`, etc.
    * Name of subdirectories as flags/options such as `--help/`, `verbose/`, etc.
6. Handles `~` and `$HOME` to navigate to home directory via `up ~` regardless of current working directory
7. Bash and Zsh compatibility

## ⚙️ Installation

Download the git repo to your preferred destination. 

I recommend using the [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir-spec/latest/) to reduce HOME directory clutter. Use either `XDG_CONFIG_HOME` or `XDG_DATA_HOME`, depending on where you like to keep shell scripts. (I imagine most people would place these into the former and consider these as configuration files.)

By default, `XDG_DATA_HOME` is `$HOME/.config` and `XDG_DATA_HOME` is `$HOME/.local/share`. However, these paths might not be explicitly defined in your shell configuration.

```sh
git clone https://github.com/LittleWalter/up ~/.config/up
```

### Bash

Add to `.bashrc` or `.bashprofile` on Apple macOS systems.

```bash
source ~/.config/up/up.bash # The `up` function
source ~/.config/up/up-completion.bash # `up` completion
```

### Zsh

Add to `.zshrc`.

These scripts are backwards compatible with Zsh; the `autoload` lines enable autocompletion modules.

```bash
autoload -U +X compinit && compinit # Enable Zsh completion 
autoload -U +X bashcompinit && bashcompinit # Enable Bash completion compatibility

source ~/.config/up/up.bash # The `up` function
source ~/.config/up/up-completion.bash # `up` completion
```

```bash
source ~/.config/up/basic_colors.bash
```

## ⌨️ Usage

For example usage, assume `pwd` command returns:

```sh
$ pwd
/Volumes/WD_SSD_1TB/Pictures/wallpapers/apple
```

### 🔢 Jump to the nth directory

```sh
$ up <optional: integer>
```

#### Jumping 1 subdirectory

```sh
$ up
$ pwd
/Volumes/WD_SSD_1TB/Pictures/wallpapers
```

#### Jumping 3 subdirectories

```sh
$ up 3
$ pwd
/Volumes/WD_SSD_1TB
```

### 📂 Jump to the nearest subdirectory name

#### Display the autocomplete list
```sh
$ up <tab>
/            Pictures/    Volumes/     WD_SSD_1TB/  wallpapers/
```

#### Autocomplete subdirectory names with prefix

To autocomplete the only subdirectory that starts with `Pic`:

```sh
$ up Pic<tab>
$ up Pictures/
```

### ⁉️ Display help

![up --help screenshot](assets/up_help_screenshot.jpg)

```sh
$ up help
$ up -h
$ up --help
```

### 📣 Verbose mode

Just like the `cd` command, `up` will generally not output text upon successful execution.

To display extra information such as `$OLDPWD` and `$PWD` after calling `up`:

```sh
$ up verbose [integer or subdirectory name]
$ up -v [integer or subdirectory name]
$ up --verbose [integer or subdirectory name]
```

#### Verbose mode examples

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

#### 🌐 `_UP_ALWAYS_VERBOSE` environment variable

Set the optional environment flag to always display verbose mode in your `.bashrc` or `.zshrc`.

```bash
export _UP_ALWAYS_VERBOSE=true
```

### 🏡 Navigate to `HOME` directory

For the sake of completeness, navigating back to `HOME` path is included.

`HOME` is the only valid full path `up` allows; all other arguments must be a single subdirectory name.

```sh
$ up ~
$ up $HOME
$ up /home/mwallace # Unix-like example
$ up /Users/vvega   # macOS example
```

You don't have to be in a `HOME` subdirectory for this to work.

## 🔬 Testing in Bats (Bash Automated Testing System)

Tests are written for [`bats-core`](https://github.com/bats-core/bats-core), a test framework for Bash.

Refer to the [official documentation of Bats](https://bats-core.readthedocs.io/en/stable/installation.html) for installation information.

### 🍺 Homebrew Installation

```sh
$ brew install bats-core
```

### 🏃 Running tests

```sh
$ bats up_test.bats # Test the `up` function
$ bats up-completion_test.bats # Test the `_up` function for Bash completions
```

## ⚠️ Limitations and Known Issues

Could be a skills issue: I'm not a Bash scripting expert.

* No color support for tab completion list
    * Could not get Zsh to use `LS_COLORS` via `zstyle` settings
* Tab completion list not in order of `PWD`
    * There's no guarantee of completion list order

## ✅ TODOs and 💡Future Ideas

Possible ideas to work on.

- [ ] Refactor `up.bash` to make it more readable
    * Easier to maintain or modify.
    * As it stands, scripts the job done as far as I can tell and well commented.
- [ ] Write a fish-compatible version.
    * I'm not using [fish](https://fishshell.com/) as my primary shell.
- [ ] Write a binary version of `up.bash` in a language like Go or Rust for universal shell compatibility. (Better idea?)
    * Only completion scripts for target shells would need to be created.
    * TUI `up` history: jump back to previous paths

## 🍿Credits

Thanks to the original script writers and public shell configs!

### [Derek Taylor's dotfiles (dwt1 on GitLab)](https://gitlab.com/dwt1/dotfiles)

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

### [Oliver Weiler's `up` Bash scripts (helpermethod on GitHub)](https://github.com/helpermethod/up)

I later found [this simple `up` Bash script](https://github.com/helpermethod/up/blob/main/up) to navigate by subdirectory name, complete with tab completion and [bats](https://bats-core.readthedocs.io/en/stable/index.html) scripts. 

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
