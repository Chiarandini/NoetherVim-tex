-- noethervim-tex auto-init.
--
-- Per the writing-neovim-plugins skill, this file owns the
-- side-effecting registration that should happen at plugin load:
--   * vim.g.loaded_noethervim_tex guard
--   * <Plug> mappings for the accent_spell module
--   * :NoetherTexAccent* user commands (registered eagerly so they
--     show up in command-line completion before any setup() call)
--   * autocmds that drive the diagnostics refresh on file events
--
-- All implementation modules are required lazily inside callbacks so
-- this file stays cheap to load.

if vim.g.loaded_noethervim_tex == 1 then return end
vim.g.loaded_noethervim_tex = 1

-- ── <Plug> mappings ───────────────────────────────────────────────────
-- We do not bind these to user-visible keys.  Users opt in by mapping
-- whatever they like (the readme suggests zG / zW / z=).
vim.keymap.set("n", "<Plug>(noethervim-tex-accent-add)", function()
  require("noethervim-tex.accent_spell").add()
end, { desc = "noethervim-tex: add accented word to spellfile" })

vim.keymap.set("n", "<Plug>(noethervim-tex-accent-mark-wrong)", function()
  require("noethervim-tex.accent_spell").mark_wrong()
end, { desc = "noethervim-tex: mark accented word as misspelled" })

vim.keymap.set("n", "<Plug>(noethervim-tex-accent-suggest)", function()
  require("noethervim-tex.accent_spell").suggest()
end, { desc = "noethervim-tex: replace accented token with a suggestion" })

-- ── User commands ─────────────────────────────────────────────────────
require("noethervim-tex.accent_spell.commands").register()

-- ── Autocmd: refresh diagnostics on buffer events ─────────────────────
-- maybe_refresh is a no-op when the feature is disabled (per-buffer or
-- globally), so registering unconditionally is safe.
local group = vim.api.nvim_create_augroup("noethervim_tex_accent_spell", { clear = true })

vim.api.nvim_create_autocmd({ "BufReadPost", "TextChanged", "TextChangedI", "InsertLeave" }, {
  group   = group,
  pattern = { "*.tex", "*.latex" },
  callback = function(args)
    require("noethervim-tex.accent_spell").maybe_refresh(args.buf)
  end,
  desc = "noethervim-tex: refresh accent spell diagnostics",
})

-- Clean up diagnostics + buffer state when the buffer is wiped.
vim.api.nvim_create_autocmd("BufWipeout", {
  group   = group,
  pattern = { "*.tex", "*.latex" },
  callback = function(args)
    pcall(function()
      require("noethervim-tex.accent_spell.diagnostics").clear(args.buf)
    end)
  end,
  desc = "noethervim-tex: clear accent diagnostics on buffer wipe",
})
