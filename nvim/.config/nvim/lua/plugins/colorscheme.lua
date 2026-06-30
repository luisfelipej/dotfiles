-- Active colorscheme is driven by the theme-set state file, with a safe fallback.
local function active_colorscheme()
  local path = vim.fn.expand("~/.local/state/theme/nvim")
  local f = io.open(path, "r")
  if f then
    local name = f:read("l")
    f:close()
    if name and #name > 0 then
      return name
    end
  end
  return "gruvbox-material"
end

local scheme = active_colorscheme()

return {
  {
    "sainnhe/gruvbox-material",
    lazy = false,
    priority = 1000,
    config = function()
      vim.opt.background = "dark"
      vim.opt.termguicolors = true
      vim.g.gruvbox_material_background = "medium"
      vim.g.gruvbox_material_foreground = "material"
      vim.g.gruvbox_material_better_performance = 1
      vim.g.gruvbox_material_enable_italic = 1
    end,
  },
  { "folke/tokyonight.nvim", lazy = true },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = scheme,
    },
  },
}
