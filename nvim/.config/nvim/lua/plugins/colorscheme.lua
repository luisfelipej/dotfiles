return {
  {
    "catppuccin/nvim",
    lazy = false,
    name = "catppuccin",
    opts = {
      flavour = "mocha",
      transparent_background = true,
      integrations = {
        mini = true,
        native_lsp = {
          enabled = true,
          underlines = {
            errors = { "undercurl" },
            hints = { "undercurl" },
            warnings = { "undercurl" },
            information = { "undercurl" },
          },
        },
      },
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "catppuccin",
    },
  },
}
