-- Boots a minimal Neovim with noethervim-tex (and plenary) on the rtp.

local plugin_root = vim.fn.fnamemodify(
  debug.getinfo(1, "S").source:sub(2), ":h:h")

vim.opt.rtp:append(plugin_root)

-- Find plenary -- it lives under different lazy roots depending on
-- which appname is active.
local plenary_candidates = {
  vim.fn.expand("~/.local/share/nvim/lazy/plenary.nvim"),
  vim.fn.expand("~/.local/share/noethervim/lazy/plenary.nvim"),
}
for _, path in ipairs(plenary_candidates) do
  if vim.uv.fs_stat(path) then
    vim.opt.rtp:append(path)
    break
  end
end

vim.cmd("runtime plugin/plenary.vim")
require("plenary.busted")
