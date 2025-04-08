#!/usr/bin/env bash
# ╻┏┓╻┏━┓╺┳╸┏━┓╻  ╻     ╻ ╻┏━┓   ┏┳┓┏━┓┏┓╻   ┏━┓┏━┓┏━╸┏━╸ ┏━┓╻ ╻
# ┃┃┗┫┗━┓ ┃ ┣━┫┃  ┃     ┃ ┃┣━┛   ┃┃┃┣━┫┃┗┫   ┣━┛┣━┫┃╺┓┣╸  ┗━┓┣━┫
# ╹╹ ╹┗━┛ ╹ ╹ ╹┗━╸┗━╸╺━╸┗━┛╹  ╺━╸╹ ╹╹ ╹╹ ╹╺━╸╹  ╹ ╹┗━┛┗━╸╹┗━┛╹ ╹
# Simple installation script for the `up` function.

# Set man page filename and paths
MANPAGE="up.1"
SYSTEM_MAN_DIR="/usr/share/man/man1/"
USER_MAN_DIR="$HOME/.local/share/man/man1/"

# Function to install the man page
install_manpage() {
	local target_dir="$1"
	echo -e "\nInstalling \`up\` man page to $target_dir"
	mkdir -p "$target_dir" || { echo "Failed to create directory $target_dir"; exit 1; }
	cp "$MANPAGE" "$target_dir" || { echo "Failed to copy $MANPAGE to $target_dir"; exit 1; }

	# Rebuild man database if installing system-wide
	if [[ "$target_dir" == "$SYSTEM_MAN_DIR" ]]; then
		echo "Updating man database..."
		sudo mandb || { echo "Failed to update man database"; exit 1; }
	fi

	echo "Man page installed successfully!"
	echo -e "Try it with: \`man up\`"
}

# Main script entry
if [[ -f "$MANPAGE" ]]; then
	echo "Choose installation type of the \`up\` man page:"
	echo "1) System-wide (requires sudo)"
	echo "2) User-specific (only for your account)"

	read -rp "Enter choice (1, 2, or anything else to quit): " choice

	case "$choice" in
		1)
			if [[ $EUID -ne 0 ]]; then
				echo "System-wide installation requires \`sudo\`. Please run this script with \`sudo\`."
				exit 1
			fi
			install_manpage "$SYSTEM_MAN_DIR"
			;;
		2)
			install_manpage "$USER_MAN_DIR"
			echo -e "\nIf necessary, add the following line to your shell config file (e.g., ~/.bashrc or ~/.zshrc):"
			echo "export MANPATH=\"$USER_MAN_DIR:\$MANPATH\""
			echo -e "Then run: \`source ~/.bashrc\` (or \`source ~/.zshrc\`)"

			if command -v manpath &>/dev/null; then
				echo -e "\n\`manpath\` currently outputs:"
				manpath
			fi
			;;
		*)
			echo "Invalid choice. Exiting."
			exit 1
			;;
	esac
else
	echo "Man page file $MANPAGE not found in the current directory."
	exit 1
fi
