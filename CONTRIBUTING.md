# 🤝 Contributing

Contributions and suggestions are welcome!

If you’d like to contribute:
1. Fork the repository.
2. Make your changes in a feature branch.
3. Open a pull request with your proposed changes.

For major changes, please open an issue to discuss what you’d like to improve.

Before submitting a pull request, please:
- Run the tests with [`bats`](https://github.com/bats-core/bats-core) to ensure everything works as expected.

## 🔬 Testing in Bats (Bash Automated Testing System)

Tests are written for [`bats-core`](https://github.com/bats-core/bats-core), a test framework for Bash.

Tested with **Bash 3.2.57(1)-release** and **Zsh 5.9** with `bash -n` to check for syntax errors.

Refer to the [official documentation of Bats](https://bats-core.readthedocs.io/en/stable/installation.html) for installation information.

###  Homebrew Installation

Cheers to easy installation methods! 🍺

```sh
$ brew install bats-core
```

### Running Tests

```sh
$ cd tests/
$ bats up_test.bats # Test the `up` function
$ bats up_completion_test.bats # Test the `_up` function for Bash completions
```
