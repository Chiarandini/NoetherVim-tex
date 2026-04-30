-- noethervim-tex.accent_spell
--
-- Top-level module for the LaTeX accent spell-check feature.
--
-- Public surface:
--   M.setup(opts)         -- patch defaults, apply decoder extras
--   M.refresh(bufnr)      -- force-rescan
--   M.maybe_refresh(bufnr)-- debounced rescan, no-op if disabled
--   M.add(word?)          -- decode cword/arg, :spellgood the Unicode form
--   M.mark_wrong(word?)   -- decode, :spellwrong
--   M.suggest()           -- vim.ui.select over spellsuggest results
--   M.enable / disable / toggle (bufnr?)
--   M.is_enabled(bufnr?)
--   M.config()            -- read-only view of resolved config
--
-- Why init logic lives partly in setup() rather than entirely in
-- plugin/noethervim_tex.lua: the decoder_extras and severity options
-- are user-tunable inputs to module behaviour, so we apply them on
-- setup().  The skill calls this out as legitimate ("must run init
-- gated on user opts").

---@class noethervim_tex.AccentSpellConfig
---@field enabled boolean
---@field severity integer        -- vim.diagnostic.severity.*
---@field debounce_ms integer
---@field decoder_extras table<string, string>

---@class noethervim_tex.AccentSpell
local M = {}

local DEFAULTS = {
  enabled = true,
  severity = vim.diagnostic.severity.INFO,
  debounce_ms = 250,
  decoder_extras = {},
}

local config = vim.tbl_deep_extend("force", {}, DEFAULTS)

-- buf -> true|false override; nil means "use global config.enabled".
local enabled_per_buf = {}
-- buf -> uv timer for debounced refresh.
local timers = {}

local function notify(msg, level)
  vim.notify("[noethervim-tex] " .. msg, level or vim.log.levels.INFO)
end

---@param opts? noethervim_tex.AccentSpellConfig
function M.setup(opts)
  config = vim.tbl_deep_extend("force", config, opts or {})

  local decoder = require("noethervim-tex.accent_spell.decoder")
  decoder._reset()
  decoder.extend(config.decoder_extras)
end

---@param bufnr? integer
---@return boolean
function M.is_enabled(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local override = enabled_per_buf[bufnr]
  if override ~= nil then return override end
  return config.enabled
end

---@param bufnr? integer
function M.enable(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  enabled_per_buf[bufnr] = true
  M.refresh(bufnr)
end

---@param bufnr? integer
function M.disable(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  enabled_per_buf[bufnr] = false
  require("noethervim-tex.accent_spell.diagnostics").clear(bufnr)
end

---@param bufnr? integer
function M.toggle(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if M.is_enabled(bufnr) then
    M.disable(bufnr)
    notify("accent spell-check disabled")
  else
    M.enable(bufnr)
    notify("accent spell-check enabled")
  end
end

---Force a rescan of the buffer regardless of debounce state.
---@param bufnr? integer
function M.refresh(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if not vim.api.nvim_buf_is_valid(bufnr) then return end
  if not M.is_enabled(bufnr) then return end
  require("noethervim-tex.accent_spell.diagnostics").refresh(bufnr, config)
end

---Schedule a refresh after the configured debounce window.
---Subsequent calls within the window reset the timer.
---@param bufnr? integer
function M.maybe_refresh(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if not vim.api.nvim_buf_is_valid(bufnr) then return end
  if not M.is_enabled(bufnr) then return end

  local existing = timers[bufnr]
  if existing then
    existing:stop()
    if not existing:is_closing() then existing:close() end
  end

  local timer = vim.uv.new_timer()
  timers[bufnr] = timer
  timer:start(config.debounce_ms, 0, vim.schedule_wrap(function()
    timer:stop()
    if not timer:is_closing() then timer:close() end
    timers[bufnr] = nil
    M.refresh(bufnr)
  end))
end

-- Find an accent token covering the cursor position, or nil.
local function token_under_cursor()
  local scanner = require("noethervim-tex.accent_spell.scanner")
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]
  if not line then return nil end
  for _, tok in ipairs(scanner.find_tokens(line)) do
    if tok.start_col - 1 <= col and col < tok.end_col then return tok end
  end
  return nil
end

local function resolve_target(word)
  if word and word ~= "" then
    local decoder = require("noethervim-tex.accent_spell.decoder")
    return decoder.decode(word) or word
  end
  local tok = token_under_cursor()
  if not tok then return nil end
  return tok.decoded
end

---@param word? string  override; default uses cword
function M.add(word)
  local target = resolve_target(word)
  if not target then
    notify("no accented token under cursor", vim.log.levels.WARN)
    return
  end
  vim.cmd("silent! spellgood " .. vim.fn.fnameescape(target))
  notify(("added %q to spellfile"):format(target))
  M.refresh()
end

---@param word? string
function M.mark_wrong(word)
  local target = resolve_target(word)
  if not target then
    notify("no accented token under cursor", vim.log.levels.WARN)
    return
  end
  vim.cmd("silent! spellwrong " .. vim.fn.fnameescape(target))
  notify(("marked %q as misspelled"):format(target))
  M.refresh()
end

---Open a picker over spellsuggest() results for the cword's decoded
---form.  The selected suggestion replaces the original LaTeX-encoded
---token with its Unicode form.  Re-encoding back to LaTeX is left for
---the user (a deliberate scope cut -- there is no canonical re-encoder).
function M.suggest()
  local tok = token_under_cursor()
  if not tok then
    notify("no accented token under cursor", vim.log.levels.WARN)
    return
  end
  local suggestions = vim.fn.spellsuggest(tok.decoded, 8, 1)
  if not suggestions or #suggestions == 0 then
    notify(("no suggestions for %q"):format(tok.decoded))
    return
  end
  vim.ui.select(suggestions, {
    prompt = ("Suggestions for %q:"):format(tok.decoded),
  }, function(choice)
    if not choice then return end
    local row = vim.api.nvim_win_get_cursor(0)[1] - 1
    vim.api.nvim_buf_set_text(0, row, tok.start_col - 1, row, tok.end_col, { choice })
    M.refresh()
  end)
end

---Read-only view of the resolved config.
---@return noethervim_tex.AccentSpellConfig
function M.config()
  local copy = {}
  for k, v in pairs(config) do copy[k] = v end
  return copy
end

return M
