--- noethervim-tex
--- LaTeX companion plugin for NoetherVim.
---
--- Provides:
---   • LuaSnip snippet collection  (LuaSnip/tex/)
---   • Treesitter queries           (queries/latex/)
---   • blink.cmp custom sources    (preambles, images)
---   • Treesitter textobject keybindings for LaTeX environments
---
--- Usage (inside noethervim.suites.latex or user config):
---   require("noethervim-tex").setup()

local M = {}

-- Resolve the noethervim-tex root dir (two levels up from this file:
-- init.lua → noethervim-tex/ → lua/ → root).
local _root = vim.fn.fnamemodify(
  debug.getinfo(1, "S").source:sub(2),
  ":h:h:h"
)

function M.setup(opts)
  opts = opts or {}

  -- Register LuaSnip snippets from this plugin's LuaSnip/ directory.
  -- This complements the user's own stdpath("config")/LuaSnip/ path.
  local ok_ls, loaders = pcall(require, "luasnip.loaders.from_lua")
  if ok_ls then
    loaders.lazy_load({ paths = _root .. "/LuaSnip/" })
  end

  -- Register LaTeX-specific treesitter-textobjects move keybindings.
  require("noethervim-tex.treesitter_textobjects").setup()
end

--- Helper functions for LuaSnip tex snippets.
--- Available as: require("noethervim-tex.luasnip_helper")
M.luasnip_helper = require("noethervim-tex.luasnip_helper")

return M
