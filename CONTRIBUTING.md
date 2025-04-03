# 🤝 Contributing

Contributions and suggestions are welcome!

If you’d like to contribute:
1. Fork the repository.
2. Make your changes in a feature branch.
3. Open a pull request with your proposed changes.

For major changes, please open an issue to discuss what you’d like to improve.

Before submitting a pull request, please:
- Run the tests with [`bats`](https://github.com/bats-core/bats-core) to ensure everything works as expected.

---

## 🔬 Testing with Bats (Bash Automated Testing System)

Tests are written for [`bats-core`](https://github.com/bats-core/bats-core), a Bash testing framework. Currently tested with:
- **Bash**: `3.2.57(1)-release`
- **Zsh**: `5.9`

Refer to the [official Bats documentation](https://bats-core.readthedocs.io/en/stable/installation.html) for installation instructions.

## 🛠 Additional Tools

- **Syntax Checking**: Use `bash -n` to check for syntax errors.
- **Linting**: [`shellcheck`](https://www.shellcheck.net) provides robust static analysis with LSP support.

### 🍺Homebrew Installation

Install `bats-core` macOS and Linux:
```sh
brew install bats-core
brew install shellcheck
```

### [Neovim](https://neovim.io/) LSP Configuration for `shellcheck` Linting with the `Lazy.nvim` Plugin Manager

Install the [Bash Language Server](https://github.com/bash-lsp/bash-language-server) via `npm`:

```
npm install -g bash-language-server
```

Add the LSP configuration plugin to [`Lazy.nvim`](https://github.com/folke/lazy.nvim), if needed:

```lua
{
    "neovim/nvim-lspconfig",
    config = function()
        require("lspconfig").bashls.setup {}
    end,
},
```

Ensure [`cmp`](https://github.com/hrsh7th/nvim-cmp) is installed in your `Lazy.nvim` configuration, for example:

```lua
{
    "hrsh7th/nvim-cmp",
    dependencies = {
        "hrsh7th/cmp-nvim-lsp", -- LSP source for cmp
        "hrsh7th/cmp-path", -- Path completion
        "hrsh7th/cmp-buffer", -- Buffer completion
    },
    config = function()
        local cmp = require("cmp")
        cmp.setup({
            mapping = cmp.mapping.preset.insert(),
            sources = {
                { name = "nvim_lsp" }, -- Autocompletion from LSP
                { name = "path" },
                { name = "buffer" },
            },
        })
    end,
},

```

Add the BashLS setup to your LSP config in Neovim, for example:

```lua
require("lspconfig").bashls.setup {
    capabilities = require("cmp_nvim_lsp").default_capabilities(vim.lsp.protocol.make_client_capabilities()),
    filetypes = { "sh", "bash" }, -- Enable for Bash scripts
    cmd = { "bash-language-server", "start" },
}
```
