--- noethervim-tex — LaTeX companion plugin for NoetherVim.
---
--- Provides:
---   • LuaSnip snippet collection   (LuaSnip/tex/)
---   • Treesitter queries            (queries/latex/)
---   • blink.cmp preamble source     (sources/preambles.lua)
---   • Treesitter textobject keymaps (]g [g ]p [p ]x [x ]c [c)
---
--- Setup:
---   require("noethervim-tex").setup({
---     preamble_folder = "~/my/preambles/",   -- default: stdpath("config")/preamble/
---     extra_snippet_paths = { "~/my/snippets/" },  -- additional LuaSnip load paths
---     textobjects = true,                    -- default: true
---   })
---
--- Writing custom snippets:
---   Create .lua files in ~/.config/<appname>/LuaSnip/tex/.
---   LuaSnip auto-loads them alongside the plugin's built-in snippets.
---   Access helper functions via:
---     local helper = require("noethervim-tex").luasnip_helper
---     local tex_utils = helper.tex_utils
---     local get_visual = helper.get_visual_node

local M = {}

-- Resolve the noethervim-tex root dir (two levels up from this file:
-- init.lua → noethervim-tex/ → lua/ → root).
local _root = vim.fn.fnamemodify(
  debug.getinfo(1, "S").source:sub(2),
  ":h:h:h"
)

--- Stored configuration, readable by other modules (e.g. sources/preambles.lua).
M.config = {}

function M.setup(opts)
  opts = opts or {}

  -- Store resolved configuration for other modules to read.
  M.config = {
    preamble_folder     = vim.fn.expand(opts.preamble_folder or (vim.fn.stdpath("config") .. "/preamble/")),
    extra_snippet_paths = opts.extra_snippet_paths or {},
    textobjects         = opts.textobjects ~= false,  -- default true
  }

  -- Register LuaSnip snippets from this plugin's LuaSnip/ directory.
  -- User snippets at stdpath("config")/LuaSnip/ are loaded separately
  -- by NoetherVim's lua-snip.lua — both coexist.
  local ok_ls, loaders = pcall(require, "luasnip.loaders.from_lua")
  if ok_ls then
    loaders.lazy_load({ paths = _root .. "/LuaSnip/" })
    -- Load any extra user-specified snippet paths.
    for _, path in ipairs(M.config.extra_snippet_paths) do
      loaders.lazy_load({ paths = vim.fn.expand(path) })
    end
  end

  -- Register LaTeX-specific treesitter-textobjects move keybindings.
  if M.config.textobjects then
    require("noethervim-tex.treesitter_textobjects").setup()
  end
end

--- Helper functions for LuaSnip tex snippets.
--- Public API — use from custom snippet files:
---   local helper = require("noethervim-tex").luasnip_helper
---   local tex_utils = helper.tex_utils
M.luasnip_helper = require("noethervim-tex.luasnip_helper")

return M
