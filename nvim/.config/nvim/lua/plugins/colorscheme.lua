return {
  {
    "rebelot/kanagawa.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      compile = false,
      dimInactive = false,
      theme = "wave",
      background = { dark = "wave" },
    },
    config = function(_, opts)
      require("kanagawa").setup(opts)
      vim.opt.background = "dark"
      vim.opt.termguicolors = true
      vim.cmd.colorscheme("kanagawa-wave")
    end,
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "kanagawa-wave",
    },
  },
}
