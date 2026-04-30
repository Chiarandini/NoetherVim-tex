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

-- ── Spell-file shipping ────────────────────────────────────────────────
-- Ship two .add files:  spell/en.utf-8.add  (math vocabulary) and
-- spell/accents.utf-8.add  (Unicode forms of common LaTeX-accented
-- proper nouns -- Kähler, Erdős, Schrödinger, …).  We compile them to
-- .spl on plugin load if missing or stale, then append to the global
-- spellfile list.  vim's :spellgood writes to the FIRST entry, which
-- the user's own config sets, so our shipped files are read-only from
-- the user's perspective.
do
  local plugin_root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h")
  local function ensure_compiled_and_appended(add_path)
    if not vim.uv.fs_stat(add_path) then return end
    local spl_path = add_path .. ".spl"
    local add_stat = vim.uv.fs_stat(add_path)
    local spl_stat = vim.uv.fs_stat(spl_path)
    local needs_build = not spl_stat
      or (add_stat and add_stat.mtime.sec > spl_stat.mtime.sec)
    if needs_build then
      pcall(vim.cmd, "silent mkspell! " .. vim.fn.fnameescape(add_path))
    end
    vim.opt.spellfile:append(add_path)
  end
  ensure_compiled_and_appended(plugin_root .. "/spell/en.utf-8.add")
  ensure_compiled_and_appended(plugin_root .. "/spell/accents.utf-8.add")
end

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
