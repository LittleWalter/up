#!/usr/bin/env bash
#-----------------------------------------------------------------------
#                                             _      _   _
# _   _ _ __         ___ ___  _ __ ___  _ __ | | ___| |_(_) ___  _ __
#| | | | '_ \ _____ / __/ _ \| '_ ` _ \| '_ \| |/ _ \ __| |/ _ \| '_ \
#| |_| | |_) |_____| (_| (_) | | | | | | |_) | |  __/ |_| | (_) | | | |
# \__,_| .__/       \___\___/|_| |_| |_| .__/|_|\___|\__|_|\___/|_| |_|
#      |_|                    _            _     _               _
#                            | |_ ___  ___| |_  | |__   __ _ ___| |__
#                            | __/ _ \/ __| __| | '_ \ / _` / __| '_ \
#                            | ||  __/\__ \ |_ _| |_) | (_| \__ \ | | |
#                         ____\__\___||___/\__(_)_.__/ \__,_|___/_| |_|
#                        |_____|
# Bash Automated Testing System (`bats`) is a testing framework 
# specifically designed for Bash scripts.
#
# This script tests the functionality of the `_up` Bash function; 
# covers most scenarios including edge cases of subdirectories 
# with integer-based names and verbose and help flags. Unicode and
# special characters as directory names tested.
#
# NOTE: All directory names in the completion list end with a slash (`/`)
# 
# To run these tests, install `bats-core`, then:
# cd </path/to/up-completion.bash>
# bats up_test.bats
#
# For Homebrew, run: `brew install bats-core`.
#
# REF: https://github.com/bats-core/bats-core
#-----------------------------------------------------------------------

load up-completion.bash

setup() {
	# Make sure Unicode characters are available to testing environment
	export LANG=en_US.UTF-8
	export LC_ALL=en_US.UTF-8
}

teardown() {
	# Remove the temporary test directory
	rm -rf "$BATS_TEST_TMPDIR"
}

assert_contains() {
	local -r expected=$1
	shift

	for e; do
		if [[ "$e" == "$expected" ]]; then
			return 0
		fi
	done
	
	# Debugging output to troubleshoot issues
	echo "Expected: $expected"
	echo "Actual: $@"
	return 1
}

@test '_up should function under UTF-8 locale' {
	setup
	[[ $LANG == "en_US.UTF-8" ]]
	[[ $LC_ALL == "en_US.UTF-8" ]]
}

@test '_up should autocomplete the list of parent directory names when given no arguments' {
	local -r path=${BATS_TEST_TMPDIR}/big/kahuna/burger
	mkdir -p "$path"
	cd "$path"

	COMP_WORDS=(up)
	COMP_CWORD=1
	_up

	assert_contains / "${COMPREPLY[@]}"
	assert_contains big/ "${COMPREPLY[@]}"
	assert_contains kahuna/ "${COMPREPLY[@]}"
}

@test '_up should not autocomplete the current directory name when given no arguments' {
	local -r path=${BATS_TEST_TMPDIR}/big/kahuna/burger
	mkdir -p "$path"
	cd "$path"

	COMP_WORDS=(up)
	COMP_CWORD=1
	_up

	! assert_contains burger/ "${COMPREPLY[@]}"
}

@test '_up should autocomplete the parent directory name' {
	local -r path=${BATS_TEST_TMPDIR}/big/kahuna/burger
	mkdir -p "$path"
	cd "$path"

	COMP_WORD=(up kah)
	COMP_CWORD=1
	_up

	assert_contains kahuna/ "${COMPREPLY[@]}"
	! assert_contains big/ "${COMPREPLY[@]}"
	! assert_contains burger/ "${COMPREPLY[@]}"
}

@test '_up should autocomplete the parent directory name containing whitespace of \"burger king\"' {
	local -r path=${BATS_TEST_TMPDIR}/big/kahuna/burger\ king/whopper
	mkdir -p "$path"
	cd "$path"

	COMP_WORD=(up burg)
	COMP_CWORD=1
	_up

	assert_contains "burger\ king/" "${COMPREPLY[@]}"
}

@test '_up should autocomplete the parent directory containing special ASCII characters of \"[burger*king&|]\"' {
	local -r path="${BATS_TEST_TMPDIR}/dir1/dir2/[burger*king&|]/dir3"
	mkdir -p "$path"
	cd "$path"

	COMP_WORD=(up \[burg)
	COMP_CWORD=1
	_up

	assert_contains "\[burger\*king\&\|\]/" "${COMPREPLY[@]}"
}

@test '_up should autocomplete parent directory containing Unicode characters in directory names' {
	local -r path=${BATS_TEST_TMPDIR}/dir1/📁/ディレクトリ/dir3
	mkdir -p "$path"
	cd "$path"

	# Set up completion environment
	COMP_WORDS=(up)
	COMP_CWORD=1

	# Call the _up function
	_up

	# Debugging output (optional, to troubleshoot issues)
	echo "COMPREPLY: ${COMPREPLY[*]}"

	# Check for expected autocompletions
	assert_contains "dir1/" "${COMPREPLY[@]}"
	assert_contains "📁/" "${COMPREPLY[@]}"
	# Ensure this test works for Unicode
	assert_contains "ディレクトリ/" "${COMPREPLY[@]}"
}

@test '_up should handle emoji-only directory names' {
	local -r path=${BATS_TEST_TMPDIR}/😊/dir2/dir3
	mkdir -p "$path"
	cd "$path"

	# Set up completion environment
	COMP_WORDS=(up)
	COMP_CWORD=1

	# Call the _up function
	_up

	# Debugging output (optional, to troubleshoot issues)
	echo "COMPREPLY: ${COMPREPLY[*]}"

	assert_contains "😊/" "${COMPREPLY[@]}"
}

@test '_up should handle mixed Unicode characters and spaces in directory names' {
	local -r path="${BATS_TEST_TMPDIR}/dir1/好 世界/dir3"  # Quote the entire path
	mkdir -p "$path"
	cd "$path"

	# Set up completion environment
	COMP_WORDS=(up)
	COMP_CWORD=1

	# Call the _up function
	_up

	# Debugging output (optional, to troubleshoot issues)
	echo "COMPREPLY: ${COMPREPLY[*]}"

	assert_contains "好\ 世界/" "${COMPREPLY[@]}"
}

@test '_up should handle combining Unicode characters in directory names' {
	local -r path=${BATS_TEST_TMPDIR}/dir1/àb̄çd̃ē/dir3
	mkdir -p "$path"
	cd "$path"

	# Set up completion environment
	COMP_WORDS=(up)
	COMP_CWORD=1

	# Call the _up function
	_up

	# Debugging output (optional, to troubleshoot issues)
	echo "COMPREPLY: ${COMPREPLY[*]}"

	assert_contains "àb̄çd̃ē/" "${COMPREPLY[@]}"
}

@test '_up should handle Cyrillic characters in directory names' {
	local -r path=${BATS_TEST_TMPDIR}/dir1/привет/dir3
	mkdir -p "$path"
	cd "$path"

	# Set up completion environment
	COMP_WORDS=(up)
	COMP_CWORD=1

	# Call the _up function
	_up

	# Debugging output (optional, to troubleshoot issues)
	echo "COMPREPLY: ${COMPREPLY[*]}"

	assert_contains "привет/" "${COMPREPLY[@]}"
}

@test '_up should handle deeply nested directories with Unicode characters' {
	local -r path="${BATS_TEST_TMPDIR}/😎/ディレクトリ/dir1/[dir2]/📂/orange julius/dir3"
	mkdir -p "$path"
	cd "$path"

	COMP_WORDS=(up)
	COMP_CWORD=1
	_up

	assert_contains "dir1/" "${COMPREPLY[@]}"
	assert_contains "\[dir2\]/" "${COMPREPLY[@]}"
	assert_contains "📂/" "${COMPREPLY[@]}"
	assert_contains "orange\ julius/" "${COMPREPLY[@]}"
}

@test '_up should autocomplete hidden directories (dot paths)' {
	local -r path=${BATS_TEST_TMPDIR}/.hidden/big/kahuna/burger
	mkdir -p "$path"
	cd "$path"

	COMP_WORD=(up .h)
	COMP_CWORD=1
	_up

	assert_contains .hidden/ "${COMPREPLY[@]}"
	! assert_contains big/ "${COMPREPLY[@]}"
	! assert_contains kahuna/ "${COMPREPLY[@]}"
	! assert_contains burger/ "${COMPREPLY[@]}"
}

@test '_up should autocomplete parent directories with special characters' {
	local -r path="${BATS_TEST_TMPDIR}/dir1/dir[2]*/dir3"
	mkdir -p "$path"
	cd "$path"

	COMP_WORDS=(up dir\[)
	COMP_CWORD=1
	_up

	assert_contains "dir\[2\]\*/" "${COMPREPLY[@]}"
}

@test '_up should handle directory names starting with special characters' {
	local -r path="${BATS_TEST_TMPDIR}/!special&dir*/dir2/taco_bell"
	mkdir -p "$path"
	cd "$path"

	COMP_WORD=(up \!)
	COMP_CWORD=1
	_up

	assert_contains "\!special\&dir\*/" "${COMPREPLY[@]}"
}

@test '_up should handle extremely long directory paths (200+ subdirectories)' {
	local base_path=${BATS_TEST_TMPDIR}
	cd "$base_path"

	# Incrementally create a path of 201 directories
	for i in $(seq 1 201); do
		next_path="dir$i/"
		mkdir "$next_path"
		cd "$next_path"
	done

	COMP_WORDS=(up)
	COMP_CWORD=1

	# Jump to the 200th directory: "dir200/"
	_up

	# Check all directories in the path
	for i in $(seq 1 200); do
		assert_contains "dir$i/" "${COMPREPLY[@]}"
	done
}
