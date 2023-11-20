<h1 align="center">Welcome to typecheck.nvim 👋</h1>
<p>
  A Neovim plugin for seamless TypeScript type checking.
</p>

## Introduction

`typecheck.nvim` is a Neovim plugin designed to enhance your TypeScript development workflow. It provides real-time type checking and integrates smoothly with Neovim's quickfix window, allowing you to easily navigate and fix type errors in your TypeScript projects.

## Features

- Asynchronous type checking: Run TypeScript compiler (`tsc`) checks without blocking the Neovim UI.
- Integration with quickfix window: View and navigate TypeScript errors and warnings directly within Neovim.
- Customizable log level: Toggle debug logging on or off.

## Installation

Include `typecheck.nvim` in your plugin manager's configuration. For example, using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
return {
  "jellydn/typecheck.nvim",
  ft = { "typescript" },
  opts = {
    debug = true, -- Allow to write log to ~/.cache/nvim/typecheck.nvim.log
    monorepo = false, -- Run tsc with --build flag for monorepo
  },
  keys = {
    {
      "<leader>ck",
      "<cmd>Typecheck<cr>",
      desc = "Run Type Check",
    },
  }
}
```

## Roadmap

`typecheck.nvim` is continuously evolving, and there are exciting plans for future enhancements. Here's what's on the horizon:

- **Bun Support**:

  - Detect and utilize Bun (a fast, modern JavaScript runtime) for TypeScript checking.
  - This feature will be explored if `bun.lock` is present and Bun is installed with TypeScript compiler (`tsc`) support.

- **Deno Integration**:
  - Implement support for Deno (a secure runtime for JavaScript and TypeScript).
  - Integration will be prioritized if `deno.lock` is detected and Deno is installed with TypeScript compiler capabilities.

These features aim to broaden the compatibility and functionality of `typecheck.nvim`, making it a more versatile tool for TypeScript developers using different environments and setups.

## Credits

- Inspired by [dmmulroy/tsc.nvim:](https://github.com/dmmulroy/tsc.nvim) A Neovim plugin for seamless, asynchronous project-wide TypeScript type-checking using the TypeScript compiler (tsc)

## Contributing

Contributions, issues, and feature requests are welcome! Feel free to check [issues page](https://github.com/jellydn/typecheck.nvim/issues).

## License

`typecheck.nvim` is available under the [MIT License](./LICENSE).

## Author

👤 **Huynh Duc Dung**

- Website: https://productsway.com/
- Twitter: [@jellydn](https://twitter.com/jellydn)
- Github: [@jellydn](https://github.com/jellydn)

## Show your support

If this guide has been helpful, please give it a ⭐️.

[![kofi](https://img.shields.io/badge/Ko--fi-F16061?style=for-the-badge&logo=ko-fi&logoColor=white)](https://ko-fi.com/dunghd)
[![paypal](https://img.shields.io/badge/PayPal-00457C?style=for-the-badge&logo=paypal&logoColor=white)](https://paypal.me/dunghd)
[![buymeacoffee](https://img.shields.io/badge/Buy_Me_A_Coffee-FFDD00?style=for-the-badge&logo=buy-me-a-coffee&logoColor=black)](https://www.buymeacoffee.com/dunghd)
