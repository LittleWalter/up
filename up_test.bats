#!/usr/bin/env bash
#-----------------------------------------------------------------------
#                _            _     _           _
#  _   _ _ __   | |_ ___  ___| |_  | |__   __ _| |_ ___
# | | | | '_ \  | __/ _ \/ __| __| | '_ \ / _` | __/ __|
# | |_| | |_) | | ||  __/\__ \ |_ _| |_) | (_| | |_\__ \
#  \__,_| .__/___\__\___||___/\__(_)_.__/ \__,_|\__|___/
#       |_| |_____|
# Bash Automated Testing System (`bats`) is a testing framework
# specifically designed for Bash scripts.
#
# This script tests the functionality of the `up` Bash function;
# covers most scenarios including edge cases of subdirectories
# with integer-based names and verbose and help flags. Unicode and
# special characters as directory names tested.
#
# To run these tests, install `bats-core`, then:
# cd </path/to/up.bash>
# bats up_test.bats
#
# For Homebrew, run: `brew install bats-core`.
#
# REF: https://github.com/bats-core/bats-core
#-----------------------------------------------------------------------

load ./up.bash

setup() {
	# Make sure Unicode characters are available to testing environment
	export LANG=en_US.UTF-8
	export LC_ALL=en_US.UTF-8

	# Disable color and other styling for testing purposes
	LABEL_STYLE=""
	ERR_STYLE=""
	DIR_CHANGE_STYLE=""
	PWD_STYLE=""
	OLDPWD_STYLE=""
	RESET=""
}

teardown() {
	# Remove the temporary test directory
	rm -rf "$BATS_TEST_TMPDIR"
}

@test 'up should function under UTF-8 locale' {
	setup
	[[ $LANG == "en_US.UTF-8" ]]
	[[ $LC_ALL == "en_US.UTF-8" ]]
}

# Standard tests #######################################################

@test 'up should jump to dir2 without args' {
	local -r path=${BATS_TEST_TMPDIR}/dir1/dir2/dir3
	mkdir -p "$path"
	cd "$path"

	up

	[[ $PWD == "${BATS_TEST_TMPDIR}/dir1/dir2" ]]
}

@test 'up should jump to dir2 with arg of 1 (int)' {
	local -r path=${BATS_TEST_TMPDIR}/dir1/dir2/dir3
	mkdir -p "$path"
	cd "$path"

	up 1

	[[ $PWD == "${BATS_TEST_TMPDIR}/dir1/dir2" ]]
}

@test 'up should jump to dir1 with arg of 2 (int)' {
	local -r path=${BATS_TEST_TMPDIR}/dir1/dir2/dir3
	mkdir -p "$path"
	cd "$path"

	up 2

	[[ $PWD == "${BATS_TEST_TMPDIR}/dir1" ]]
}

@test 'up should jump up 1 directory on empty string' {
	local -r path=${BATS_TEST_TMPDIR}/dir1/dir2/dir3
	mkdir -p "$path"
	cd "$path"

	up ""

	[[ $PWD == "${BATS_TEST_TMPDIR}/dir1/dir2" ]]
}

@test 'up should jump to dir1 with arg of 00002 (int with leading 0s)' {
	local -r path=${BATS_TEST_TMPDIR}/dir1/dir2/dir3
	mkdir -p "$path"
	cd "$path"

	up 00002

	[[ $PWD == "${BATS_TEST_TMPDIR}/dir1" ]]
}

@test 'up should jump to subdirectory 1/ (int with trailing slash)' {
	local -r path=${BATS_TEST_TMPDIR}/1/dir2/dir3
	mkdir -p "$path"
	cd "$path"

	up 1/

	[[ $PWD == "${BATS_TEST_TMPDIR}/1" ]]
}

@test 'up should jump to subdirectory name of dir1 (no trailing slash)' {
	local -r path=${BATS_TEST_TMPDIR}/dir1/dir2/dir3
	mkdir -p "$path"
	cd "$path"

	up dir1

	[[ $PWD == "${BATS_TEST_TMPDIR}/dir1" ]]
}

@test 'up should jump to subdirectory name of dir1/ (with trailing slash)' {
	local -r path=${BATS_TEST_TMPDIR}/dir1/dir2/dir3
	mkdir -p "$path"
	cd "$path"

	up dir1/

	[[ $PWD == "${BATS_TEST_TMPDIR}/dir1" ]]
}

@test 'up should jump to subdirectory name of dir2/' {
	local -r path=${BATS_TEST_TMPDIR}/dir1/dir2/dir3
	mkdir -p "$path"
	cd "$path"

	up dir2/

	[[ $PWD == "${BATS_TEST_TMPDIR}/dir1/dir2" ]]
}

@test 'up should jump to subdirectory name of a negative integer' {
	local -r path=${BATS_TEST_TMPDIR}/dir1/-4/dir2/dir3
	mkdir -p "$path"
	cd "$path"

	up -4/

	# It should not be possible to "jump negative directories", rather
	# -4 should be considered the directory "-4/"
	[[ $PWD == "${BATS_TEST_TMPDIR}/dir1/-4" ]]
}

@test 'up should not change directory on unknown subdirectory name (\"missing_dir\")' {
	local -r path=${BATS_TEST_TMPDIR}/dir1/dir2/dir3
	mkdir -p "$path"
	cd "$path"

	run up missing_dir

	# Bad news is good news: assertion failure
	[ $status -ne 0 ]
}

@test 'up should not change directory on unknown subdirectory name (\"pink\") when it has similar trailing chars as another' {
	local -r path=${BATS_TEST_TMPDIR}/dir1/mr_pink/dir3
	mkdir -p "$path"
	cd "$path"

	run up pink

	# Debugging: print output on failure
	echo "$output"


	# Bad news is good news: assertion failure
	[ $status -ne 0 ]
}

@test 'up should not change directory on unknown subdirectory name but PWD contains the substring' {
	local -r path=${BATS_TEST_TMPDIR}/dir1/substring_check/dir3
	mkdir -p "$path"
	cd "$path"

	run up substring

	# Bad news is good news: assertion failure
	[ $status -ne 0 ]
}

# Character-related tests ##############################################

@test 'up should jump to subdirectory with whitespace name of \"big kahuna burger\"' {
	local -r path=${BATS_TEST_TMPDIR}/dir1/big\ kahuna\ burger/dir2/dir3
	mkdir -p "$path"
	cd "$path"

	up big\ kahuna\ burger

	[[ $PWD == "${BATS_TEST_TMPDIR}/dir1/big kahuna burger" ]]
}

@test 'up should jump to subdirectory with special ASCII characters of \"[burger*king&|]\"' {
	local -r path="${BATS_TEST_TMPDIR}/dir1/[burger*king&|]/dir2/dir3"
	mkdir -p "$path"
	cd "$path"
	echo "$path"

	up \[burger\*king\&\|\]

	[[ $PWD == "${BATS_TEST_TMPDIR}/dir1/[burger*king&|]" ]]
}

@test 'up should handle Unicode characters in directory names' {
	local -r path=${BATS_TEST_TMPDIR}/dir1/ダン·メイソン/📁/dir3
	mkdir -p "$path"
	cd "$path"

	up ダン·メイソン

	[[ $PWD == "${BATS_TEST_TMPDIR}/dir1/ダン·メイソン" ]]
}

@test 'up should handle emoji-only directory names' {
	local -r path=${BATS_TEST_TMPDIR}/😊/dir2/dir3
	mkdir -p "$path"
	cd "$path"

	up 😊

	[[ $PWD == "${BATS_TEST_TMPDIR}/😊" ]]
}

@test 'up should handle mixed Unicode characters and spaces' {
	local -r path="${BATS_TEST_TMPDIR}/dir1/好 世界/dir3"  # Quote the entire path
	mkdir -p "$path"
	cd "$path"

	up "好 世界"  # Quote the argument as well

	[[ $PWD == "${BATS_TEST_TMPDIR}/dir1/好 世界" ]]
}

@test 'up should handle combining Unicode characters' {
	local -r path=${BATS_TEST_TMPDIR}/dir1/àb̄çd̃ē/dir3
	mkdir -p "$path"
	cd "$path"

	up àb̄çd̃ē

	[[ $PWD == "${BATS_TEST_TMPDIR}/dir1/àb̄çd̃ē" ]]
}

@test 'up should handle Cyrillic characters in directory names' {
	local -r path=${BATS_TEST_TMPDIR}/dir1/привет/dir3
	mkdir -p "$path"
	cd "$path"

	up привет

	[[ $PWD == "${BATS_TEST_TMPDIR}/dir1/привет" ]]
}

# Not-a-flag tests #####################################################

@test 'up should jump to subdirectory named \"--verbose/\" (flag)' {
	local -r path=${BATS_TEST_TMPDIR}/--verbose/big\ kahuna\ burger/dir2/dir3
	mkdir -p "$path"
	cd "$path"

	up --verbose/

	[[ $PWD == "${BATS_TEST_TMPDIR}/--verbose" ]]
}

@test 'up should jump to subdirectory named \"verbose/\" (flag)' {
	local -r path=${BATS_TEST_TMPDIR}/verbose/big\ kahuna\ burger/dir2/dir3
	mkdir -p "$path"
	cd "$path"

	up verbose/

	[[ $PWD == "${BATS_TEST_TMPDIR}/verbose" ]]
}

@test 'up should jump to subdirectory named \"-v/\" (flag)' {
	local -r path=${BATS_TEST_TMPDIR}/-v/big\ kahuna\ burger/dir2/dir3
	mkdir -p "$path"
	cd "$path"

	up -v/

	[[ $PWD == "${BATS_TEST_TMPDIR}/-v" ]]
}

@test 'up should jump to subdirectory named \"help/\" (flag)' {
	local -r path=${BATS_TEST_TMPDIR}/help/big\ kahuna\ burger/dir2/dir3
	mkdir -p "$path"
	cd "$path"

	up help/

	[[ $PWD == "${BATS_TEST_TMPDIR}/help" ]]
}

@test 'up should jump to subdirectory named \"--help/\" (flag)' {
	local -r path=${BATS_TEST_TMPDIR}/--help/big\ kahuna\ burger/dir2/dir3
	mkdir -p "$path"
	cd "$path"

	up --help/

	[[ $PWD == "${BATS_TEST_TMPDIR}/--help" ]]
}

@test 'up should jump to subdirectory named \"-h/\" (flag)' {
	local -r path=${BATS_TEST_TMPDIR}/-h/big\ kahuna\ burger/dir2/dir3
	mkdir -p "$path"
	cd "$path"

	up -h/

	[[ $PWD == "${BATS_TEST_TMPDIR}/-h" ]]
}

# Special directory tests #############################################

@test 'up should change to device root (/)' {
	local -r path=${BATS_TEST_TMPDIR}/dir1/dir2/dir3
	mkdir -p "$path"
	cd "$path"

	up /

	[[ $PWD == "/" ]]
}

@test 'up should change to HOME path of user (~)' {
	local -r path=${BATS_TEST_TMPDIR}/dir1/dir2/dir3
	mkdir -p "$path"
	cd "$path"

	up ~

	[[ $PWD == $HOME ]]
}

@test 'up should change to HOME path of user ($HOME)' {
	local -r path=${BATS_TEST_TMPDIR}/dir1/dir2/dir3
	mkdir -p "$path"
	cd "$path"

	up $HOME

	# Debugging: print output on failure
	echo "$output"

	[[ $PWD == $HOME ]]
}

@test 'up should handle unset HOME variable and jump 1 directory' {
	local -r path=${BATS_TEST_TMPDIR}/dir1/dir2/dir3
	mkdir -p "$path"
	cd "$path"

	local original_home=$HOME
	unset HOME

	run up $HOME

	[ $status -eq 0 ]
	[[ $PWD == "${BATS_TEST_TMPDIR}/dir1/dir2" ]]

	export HOME=$original_home  # Restore the original value
}

# Verbose flag tests ###################################################

@test 'up should print verbose text passing -v flag and int of 2' {
	local -r path=${BATS_TEST_TMPDIR}/dir1/dir2/dir3
	mkdir -p "$path"
	cd "$path"

	run up -v 2

	# Debugging: print output on failure
	echo "$output"

	# Use grep to check for a regex match in the output of line 1
	local test_output=
	echo "$output" | grep -q "up: jumped 2 dirs$"
	# Assert that grep succeeded
	[ "$?" -eq 0 ]

	# Use grep to check for a regex match in the output of line 2
	echo "$output" | grep -q "old: $path$"
	# Assert that grep succeeded
	[ "$?" -eq 0 ]

	# Use grep to check for a regex match in the output of line 3
	echo "$output" | grep -q "pwd: .*/dir1$"
	# Assert that grep succeeded
	[ "$?" -eq 0 ]
}

@test 'up should print verbose text passing --verbose flag and no arg' {
	local -r path=${BATS_TEST_TMPDIR}/dir1/dir2/dir3
	mkdir -p "$path"
	cd "$path"

	run up --verbose

	# Debugging: print output on failure
	echo "$output"

	# Use grep to check for a regex match in the output of line 1
	echo "$output" | grep -q "up: jumped 1 dir$"
	# Assert that grep succeeded
	[ "$?" -eq 0 ]

	# Use grep to check for a regex match in the output of line 2
	echo "$output" | grep -q "old: $path$"
	# Assert that grep succeeded
	[ "$?" -eq 0 ]

	# Use grep to check for a regex match in the output of line 3
	echo "$output" | grep -q "pwd: .*/dir1/dir2$"
	# Assert that grep succeeded
	[ "$?" -eq 0 ]
}

@test 'up should print verbose text passing --verbose flag with arg of dir2' {
	local -r path=${BATS_TEST_TMPDIR}/dir1/dir2/dir3
	mkdir -p "$path"
	cd "$path"

	run up --verbose dir2

	# Debugging: print output on failure
	echo "$output"

	# Use grep to check for a regex match in the output of line 1
	echo "$output" | grep -q "up: jumped 1 dir to nearest: dir2"
	# Assert that grep succeeded
	[ "$?" -eq 0 ]

	# Use grep to check for a regex match in the output of line 2
	echo "$output" | grep -q "old: $path$"
	# Assert that grep succeeded
	[ "$?" -eq 0 ]

	# Use grep to check for a regex match in the output of line 3
	echo "$output" | grep -q "pwd: .*/dir1/dir2$"
	# Assert that grep succeeded
	[ "$?" -eq 0 ]
}

@test 'up should print verbose text passing --verbose flag with arg of dir1' {
	local -r path=${BATS_TEST_TMPDIR}/dir1/dir2/dir3
	mkdir -p "$path"
	cd "$path"

	run up --verbose dir1

	# Debugging: print output on failure
	echo "$output"

	# Use grep to check for a regex match in the output of line 1
	echo "$output" | grep -q "up: jumped 2 dirs to nearest: dir1$"
	# Assert that grep succeeded
	[ "$?" -eq 0 ]

	# Use grep to check for a regex match in the output of line 2
	echo "$output" | grep -q "old: $path$"
	# Assert that grep succeeded
	[ "$?" -eq 0 ]

	# Use grep to check for a regex match in the output of line 3
	echo "$output" | grep -q "pwd: .*/dir1$"
	# Assert that grep succeeded
	[ "$?" -eq 0 ]
}

# Help flag tests ######################################################

@test 'up should print help text when passing --help flag' {
	local -r path=${BATS_TEST_TMPDIR}/dir1/dir2/dir3
	mkdir -p "$path"
	cd "$path"

	run up --help

	# Debugging: print output on failure
	echo "$output"

	# Use grep to check for a regex match in the output of line 1
	echo "$output" | grep -q "Jump the directory tree instead of using \`cd ..\` chains!"
	# Assert that grep succeeded
	[ "$?" -eq 0 ]
}

@test 'up should print help text when passing -h flag' {
	local -r path=${BATS_TEST_TMPDIR}/dir1/dir2/dir3
	mkdir -p "$path"
	cd "$path"

	run up -h

	# Debugging: print output on failure
	echo "$output"

	# Use grep to check for a regex match in the output of line 1
	echo "$output" | grep -q "Jump the directory tree instead of using \`cd ..\` chains!"
	# Assert that grep succeeded
	[ "$?" -eq 0 ]
}
