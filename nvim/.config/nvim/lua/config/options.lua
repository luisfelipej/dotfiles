-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Clipboard over SSH. LazyVim clears 'clipboard' when SSH_CONNECTION is set,
-- and inside tmux nvim picks pbcopy, which writes to the REMOTE machine's
-- clipboard. OSC 52 travels back through ssh/tmux to Ghostty, which puts the
-- text on the local clipboard instead.
local function over_ssh()
  if vim.env.SSH_TTY or vim.env.SSH_CONNECTION then
    return true
  end
  -- A tmux session created locally and later attached over ssh doesn't have
  -- SSH_* in the pane env, but tmux refreshes it in the session env on attach.
  if vim.env.TMUX then
    local out = vim.fn.system({ "tmux", "show-environment", "SSH_CONNECTION" })
    return vim.v.shell_error == 0 and not out:match("^%-")
  end
  return false
end

if over_ssh() then
  local osc52 = require("vim.ui.clipboard.osc52")
  -- Reading the clipboard over OSC 52 blocks or prompts in most terminals;
  -- paste from nvim's own register instead (Cmd+V still works for local text).
  local function paste()
    return { vim.fn.split(vim.fn.getreg(""), "\n"), vim.fn.getregtype("") }
  end
  vim.g.clipboard = {
    name = "OSC 52",
    copy = { ["+"] = osc52.copy("+"), ["*"] = osc52.copy("*") },
    paste = { ["+"] = paste, ["*"] = paste },
  }
  vim.opt.clipboard = "unnamedplus"
end
