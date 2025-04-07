#                    _                _
# _   _ _ __  __   _| |__  ___     __| | ___ _ __ ___   ___
#| | | | '_ \ \ \ / / '_ \/ __|   / _` |/ _ \ '_ ` _ \ / _ \
#| |_| | |_) | \ V /| | | \__ \  | (_| |  __/ | | | | | (_) |
# \__,_| .__/___\_/ |_| |_|___/___\__,_|\___|_| |_| |_|\___/
#      |_| |_____|           |_____| _
#                                   | |_ __ _ _ __   ___
# Programmatic animated terminal    | __/ _` | '_ \ / _ \
# GIF generator courtesy of `vhs`   | || (_| | |_) |  __/
# by charmbracelet.                (_)__\__,_| .__/ \___|
#                                            |_|
# REF: https://github.com/charmbracelet/vhs

# Where should we write the GIF?
Output up_vhs_demo_animation.gif

# Set up a 1920x1080 (FHD) terminal with 32px font.
Set FontFamily "JetBrainsMonoNL Nerd Font"
Set FontSize 32
Set Width 1920
Set Height 1080
Set WindowBar Colorful
Set TypingSpeed 115ms
Set Theme "Catppuccin Mocha"
Set Margin 20
Set MarginFill "#CBA6F7"
Set BorderRadius 15
Set PlaybackSpeed 2.0

# Load `up` and `_up` tab completion
Hide
# TIP: Change this path, if necessary
Type "cd ~/.config_repo/zsh/.local/share/zsh/plugins/up"
Enter
Type "source ./up.bash"
Enter
Type "source ./up_completion.bash"
Enter
# TIP: Change this path, if necessary
Type "cd /Volumes/WD_SSD_1TB/Pictures/wallpapers/apple"
Enter
Type "up --clear"
Enter
Type "clear"
Enter
Show

# Intro message
Type "# Jump `up` the PWD tree with ease!"
# Pause for dramatic effect...
Sleep 2s
Enter
# Admire the output for a bit.
Sleep 3s

# Change into the demo path
Type "pwd"
Enter
Sleep 2s

# Demo: `up <tab>`
Type "# Jump to an ancestor directory name with tab completion"
Sleep 3s
Enter
Type "up "
Tab@2s 2
Sleep 2s
Type "Pic"
Sleep 3s
Tab@2s 2
Enter
Sleep 2s
Type "pwd"
Enter
Sleep 3s

Type "# Jump to the parent directory"
Sleep 3s
Enter
Type "up"
Sleep 2s
Enter
Sleep 2s
Type "pwd"
Sleep 2s
Enter
Sleep 3s

Type "# Jump up by directory index (e.g., to grandparent)"
Sleep 3s
Enter
Type "up 2"
Enter
Sleep 2s
Type "pwd"
Enter
Sleep 3s

Type "cd /Volumes/WD_SSD_1TB/Pictures/wallpapers/apple"
Enter
Sleep 3s

Type "# Show verbose output!"
Sleep 3s
Enter
Sleep 2s
Type "up -v 2"
Enter
Sleep 5s

Type "# Even use basic regex matches to jump into an ancestor directory!"
Sleep 3s
Enter
Type "cd /Volumes/WD_SSD_1TB/Pictures/wallpapers/apple"
Enter
Sleep 2s
Type "up -riv ssd # -r to match nearest directory anywhere in name and -i to ignore case"
Sleep 4s
Enter
Sleep 7s

Type "# Try using `fzf`, the fuzzy finder, to inspect and jump somewhere in your PWD!"
Sleep 4s
Enter
Sleep 3s
Type "# NOTE: The default fzf options are <CTRL-J>/<CTRL-K> for PGDN/PGUP in the"
Enter
Type "# preview window and <CTRL-P> to toggle it. <CTRL-L> to show `ls` info,"
Enter
Type "# <CTRL-T> for tree view, and <CTRL-I> for `stat` information..."
Sleep 8s
Enter
Type "cd /Volumes/WD_SSD_1TB/Pictures/wallpapers/apple"
Enter
Sleep 2s

Type "up --fzf --verbose # or `up -fv`"
Sleep 4s
Enter
Sleep 10s
Ctrl+j
Sleep 2s
Ctrl+j
Sleep 2s
Ctrl+j
Sleep 2s
Ctrl+j
Sleep 8s
Down
Sleep 8s
Ctrl+l
Sleep 8s
Ctrl+i
Sleep 8s
Ctrl+t
Sleep 8s
Down
Sleep 8s
Enter

Type "# Optionally, jump to path history when you add `export _UP_ENABLE_HIST=true`"
Enter
Type "# to your .bashrc, .zshrc, or .zshenv"
Sleep 3s
Enter
Type "# Use the helper function `up_passthru` to capture and track changes made by `cd`,"
Enter
Type "# `zoxide`, `jump`, and other commands that change directories..."
Sleep 5s
Enter
Type "up_passthru --help"
Sleep 2s
Enter
Sleep 10s
Type "up -Fv # or `up --fzf-hist --verbose`"
Sleep 5s
Enter
Sleep 3s
Down
Sleep 3s
Ctrl+p
Sleep 2s
Ctrl+l
Sleep 5s
Enter

Sleep 8s
