-- noethervim-tex.accent_spell.diagnostics
--
-- Two responsibilities, both keyed off the scanner's token list:
--
-- 1. Emit  vim.diagnostic  entries for tokens whose decoded form fails
--    vim.fn.spellbadword().  The diagnostic spans the WHOLE
--    LaTeX-encoded token, not a fragment -- that's the entire point
--    of going through diagnostics rather than vim's syntax-aware
--    spell, which gives up on letters in the shadow of a concealed
--    accent.
--
-- 2. Drop  spell = false  extmarks over every successfully-decoded
--    token so vim's native SpellBad highlight doesn't double-flag the
--    fragments (`ahler`, `older`, …) we've already taken responsibility
--    for.  Without this, a correctly-spelled  K\"ahler  shows a red
--    underline on `ahler` even though our diagnostic stays silent.

---@class noethervim_tex.AccentSpellDiagnostics
local M = {}

local NS_DIAG = vim.api.nvim_create_namespace("noethervim_tex_accent_spell")
-- Separate namespace for spell-suppression extmarks so they have an
-- independent lifecycle from the diagnostic list.  We clear and
-- repopulate this namespace on every refresh.
local NS_SUPPRESS = vim.api.nvim_create_namespace("noethervim_tex_accent_spell_suppress")

---@param bufnr integer
---@param config noethervim_tex.AccentSpellConfig
function M.refresh(bufnr, config)
  if not vim.api.nvim_buf_is_valid(bufnr) then return end

  local scanner = require("noethervim-tex.accent_spell.scanner")
  local tokens = scanner.scan(bufnr)

  -- Clear stale spell-suppression extmarks before laying down new ones.
  vim.api.nvim_buf_clear_namespace(bufnr, NS_SUPPRESS, 0, -1)

  local diagnostics = {}
  for _, tok in ipairs(tokens) do
    -- Build extmark attrs.  spell=false disables vim's native
    -- fragment-level squiggle on this span.  For typo tokens we also
    -- attach hl_group=SpellBad so the user gets the visual signal
    -- they expect (red underline) on the WHOLE token, not on the
    -- broken-letter fragment that vim's tokeniser would otherwise see.
    local attrs = {
      end_row = tok.range[3],
      end_col = tok.range[4],
      spell = false,
    }

    if not tok.is_in_math then
      local res = vim.fn.spellbadword(tok.decoded)
      if res[1] and res[1] ~= "" then
        -- Highlight always applies; diagnostic is gated so users can
        -- silence the diagnostic-list / signcolumn / Trouble entry
        -- while keeping the visual red squiggle.
        attrs.hl_group = "SpellBad"
        if config.emit_diagnostic ~= false then
          diagnostics[#diagnostics + 1] = {
            lnum     = tok.range[1],
            col      = tok.range[2],
            end_lnum = tok.range[3],
            end_col  = tok.range[4],
            severity = config.severity or vim.diagnostic.severity.INFO,
            source   = "noethervim-tex.accent-spell",
            message  = ("possible misspelling: %s"):format(tok.decoded),
            user_data = { raw = tok.raw, decoded = tok.decoded },
          }
        end
      end
    end

    vim.api.nvim_buf_set_extmark(bufnr, NS_SUPPRESS, tok.range[1], tok.range[2], attrs)
  end

  vim.diagnostic.set(NS_DIAG, bufnr, diagnostics)
end

---@param bufnr integer
function M.clear(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then return end
  vim.diagnostic.reset(NS_DIAG, bufnr)
  vim.api.nvim_buf_clear_namespace(bufnr, NS_SUPPRESS, 0, -1)
end

---@return integer  the diagnostic namespace id
function M.namespace()
  return NS_DIAG
end

---@return integer  the spell-suppression extmark namespace id
function M.suppress_namespace()
  return NS_SUPPRESS
end

return M
