<h1 align="center">Welcome to typecheck.nvim 👋</h1>
<p>
  A Neovim plugin for seamless TypeScript type checking.
</p>

[![IT Man - Revolutionize Your TypeScript with typecheck.nvim [Vietnamese]](https://i.ytimg.com/vi/XkH--D09ENY/hqdefault.jpg)](https://www.youtube.com/watch?v=XkH--D09ENY)

## Introduction

`typecheck.nvim` is a Neovim plugin designed to enhance your TypeScript development workflow. It provides real-time type checking and integrates smoothly with Neovim's quickfix window, allowing you to easily navigate and fix type errors in your TypeScript projects.

## Features

- Asynchronous type checking: Run TypeScript compiler (`tsc`) checks without blocking the Neovim UI.
- Integration with quickfix or [trouble.nvim](https://github.com/folke/trouble.nvim) window: View and navigate TypeScript errors and warnings directly within Neovim.

## Installation

Include `typecheck.nvim` in your plugin manager's configuration. For example, using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
return {
  "jellydn/typecheck.nvim",
  dependencies = { "folke/trouble.nvim", dependencies = { "nvim-tree/nvim-web-devicons" } },
  ft = { "javascript", "javascriptreact", "json", "jsonc", "typescript", "typescriptreact" },
  opts = {
    debug = true,
    mode = "trouble", -- "quickfix" | "trouble"
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

### Demo

Run `:Typecheck` to start type checking. The quickfix window will open if there are any errors or warnings.

[![Demo](https://i.gyazo.com/5009755ceb575afc78d7303983a2f7c0.gif)](https://gyazo.com/5009755ceb575afc78d7303983a2f7c0)

#### Integration with [trouble.nvim](https://github.com/folke/trouble.nvim)

[![Show on Trouble](https://i.gyazo.com/fc367f6cc005dd53f696c299e383318a.gif)](https://gyazo.com/fc367f6cc005dd53f696c299e383318a)

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
