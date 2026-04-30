-- noethervim-tex.accent_spell.diagnostics
--
-- Owns the vim.diagnostic namespace for accent spell-check.  refresh()
-- runs the scanner, decodes each token, asks vim's spell engine
-- whether the decoded form is a real word, and emits an INFO-level
-- diagnostic over the full LaTeX-encoded token range when it isn't.
-- The whole-token range is the entire point of going through
-- diagnostics rather than syntax: vim's syntax-aware spell tokeniser
-- ignores letters in the shadow of a concealed accent, so a typo in
-- the trailing portion never lights up.

---@class noethervim_tex.AccentSpellDiagnostics
local M = {}

local NS = vim.api.nvim_create_namespace("noethervim_tex_accent_spell")

---@param bufnr integer
---@param config noethervim_tex.AccentSpellConfig
function M.refresh(bufnr, config)
  if not vim.api.nvim_buf_is_valid(bufnr) then return end

  local scanner = require("noethervim-tex.accent_spell.scanner")
  local tokens = scanner.scan(bufnr)

  local diagnostics = {}
  for _, tok in ipairs(tokens) do
    if not tok.is_in_math then
      local res = vim.fn.spellbadword(tok.decoded)
      if res[1] and res[1] ~= "" then
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

  vim.diagnostic.set(NS, bufnr, diagnostics)
end

---@param bufnr integer
function M.clear(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then return end
  vim.diagnostic.reset(NS, bufnr)
end

---@return integer  the namespace id
function M.namespace()
  return NS
end

return M
