-- Seamless C-hjkl between Neovim splits and Zellij panes.
-- Replaces vim-tmux-navigator, which was declared in .tmux.conf but never had
-- a Neovim counterpart installed, so the navigation never actually worked.
-- Zellij's default C-h binding is unbound in config.kdl so these reach Neovim.
return {
  "swaits/zellij-nav.nvim",
  lazy = true,
  event = "VeryLazy",
  keys = {
    { "<c-h>", "<cmd>ZellijNavigateLeftTab<cr>", desc = "Navigate Left (or Tab)" },
    { "<c-j>", "<cmd>ZellijNavigateDown<cr>", desc = "Navigate Down" },
    { "<c-k>", "<cmd>ZellijNavigateUp<cr>", desc = "Navigate Up" },
    { "<c-l>", "<cmd>ZellijNavigateRightTab<cr>", desc = "Navigate Right (or Tab)" },
  },
  opts = {},
}
