-- Light: zenwritten (zenbones' neutral-gray flavor). Dark: kanagawa-wave.
-- Both follow the macOS appearance, live, the same as Ghostty.

-- `defaults` prints "Dark" in dark mode and exits non-zero in light mode.
local function system_is_dark()
  local out = vim.fn.system({ "defaults", "read", "-g", "AppleInterfaceStyle" })
  return vim.v.shell_error == 0 and out:match("Dark") ~= nil
end

-- 'background' goes first: zenwritten picks its variant from it at load time.
local function apply(dark)
  vim.o.background = dark and "dark" or "light"
  vim.cmd.colorscheme(dark and "kanagawa-wave" or "zenwritten")
end

return {
  {
    "rebelot/kanagawa.nvim",
    lazy = true,
    opts = {
      compile = false,
      dimInactive = false,
      theme = "wave",
      background = { dark = "wave" },
    },
  },
  {
    "zenbones-theme/zenbones.nvim",
    dependencies = { "rktjmp/lush.nvim" },
    lazy = true,
  },
  {
    -- Polls the appearance and swaps the colorscheme in every open nvim.
    "f-person/auto-dark-mode.nvim",
    event = "VeryLazy",
    opts = {
      update_interval = 1000,
      set_dark_mode = function()
        apply(true)
      end,
      set_light_mode = function()
        apply(false)
      end,
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = function()
        vim.o.termguicolors = true
        apply(system_is_dark())
      end,
    },
  },
}
