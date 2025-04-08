# `up` Man Page

## Purpose

The `up` man page serves as a comprehensive and accessible manual for using `up`. It provides detailed usage instructions and options, offering more in-depth information than a README or the `up --help` command.

## Installation

To install the optional `up` man page, you can either manually move the `up.1` file to your preferred location or use the provided installation script for convenience.

### Using the Installation Script

1. Navigate to the directory containing the man page and script:

```sh
cd ~/.config/shell/up/man # Or the directory where you placed these files
```

2. Ensure the installation script is executable:

```sh
chmod +x install_up_man_page.bash
```

3. Run the installation script:

```sh
./install_up_man_page.bash
```

The script gives you the option to install the man page either system-wide or for your user account only.

### Verifying Installation

To check if the man page is available, run:
```sh
man up
```

If the man page is not found, confirm your man page paths using:

```sh
manpath
```

### Manual Installation

If you prefer, you can manually move the up.1 man page to the appropriate location. For example:

```sh
mv up.1 /usr/local/share/man/man1/ # For a system-wide installation
mv up.1 ~/.local/share/man/man1/  # For a user-specific installation
```

After moving the file, update your man database (if required):

```sh
mandb # for system-wide installation
```

## Notes

* The `man` page provides advanced usage information for up and complements the `up --help` command.
* Ensure your `MANPATH` is correctly configured to include the directory where the `up.1` file is installed.
  - On Apple macOS, both system-wide and user-specific paths may already be defined within the `manpath` output.
