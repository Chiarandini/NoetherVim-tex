-- noethervim-tex.accent_spell.scanner
--
-- Finds LaTeX-accented word tokens in a buffer or in a line of text.
--
-- The latex treesitter grammar splits a word like  K\"ahler  into
-- sibling nodes (word "K", generic_command "\"", word "ahler"); there
-- is no single node for the whole accented token.  So we use a
-- byte-level scan to identify token spans, and treesitter only to
-- exclude math regions and comments at the buffer level.  The pure
-- find_tokens() function is therefore independently testable without a
-- parser.

---@class noethervim_tex.AccentToken
---@field range { [1]: integer, [2]: integer, [3]: integer, [4]: integer } -- start_row, start_col, end_row, end_col (0-indexed, end-exclusive byte cols)
---@field raw string
---@field decoded string
---@field is_in_math boolean

---@class noethervim_tex.AccentLineToken
---@field start_col integer  -- 1-indexed byte col where token begins
---@field end_col integer    -- 1-indexed byte col where token ends (inclusive)
---@field raw string
---@field decoded string

---@class noethervim_tex.AccentScanner
local M = {}

local decoder = require("noethervim-tex.accent_spell.decoder")

-- Punctuation accents: usable as bare \"a or braced \"{a}.
local PUNCT_ACCENTS = "`'^\"~.="
-- Letter accents: braces required.
local LETTER_ACCENTS = "cHkruv"

local function in_set(set, c)
  return set:find(c, 1, true) ~= nil
end

---Returns the 1-indexed column where the accent macro starting at
---`pos` ends (inclusive), or nil if no accent macro starts here.
---
---Recognises:
---  \"a          (bare punct + letter)
---  \"{a}        (braced punct + letter)
---  \"\i  \"\j   (punct + dotless)
---  \"{\i}       (braced punct + braced dotless)
---  \H{o}        (letter accent + letter; braces required)
---  \H{\i}       (letter accent + braced dotless)
---
---Standalone \i / \j (without a preceding accent) are NOT treated as
---accent-macro starts -- a token of just "\i" decodes to "ı" but
---carries no spell-check signal worth flagging.
---@param line string
---@param pos integer  1-indexed byte col
---@return integer|nil  end col (inclusive)
local function accent_macro_end(line, pos)
  if line:sub(pos, pos) ~= "\\" then return nil end
  if pos + 1 > #line then return nil end
  local accent = line:sub(pos + 1, pos + 1)

  if in_set(PUNCT_ACCENTS, accent) then
    local p = pos + 2
    if p > #line then return nil end
    local c = line:sub(p, p)

    if c == "{" then
      local close = line:find("}", p + 1, true)
      if not close then return nil end
      local inner = line:sub(p + 1, close - 1)
      if inner:match("^%a$") or inner == "\\i" or inner == "\\j" then
        return close
      end
      return nil
    elseif c == "\\" then
      if p + 1 > #line then return nil end
      local letter = line:sub(p + 1, p + 1)
      if letter == "i" or letter == "j" then return p + 1 end
      return nil
    elseif c:match("%a") then
      return p
    end
    return nil
  elseif in_set(LETTER_ACCENTS, accent) then
    local p = pos + 2
    if p > #line or line:sub(p, p) ~= "{" then return nil end
    local close = line:find("}", p + 1, true)
    if not close then return nil end
    local inner = line:sub(p + 1, close - 1)
    if inner:match("^%a$") or inner == "\\i" or inner == "\\j" then return close end
    return nil
  end
  return nil
end

---Find the first accent macro at or after `pos` in `line`.
---@return integer|nil start_col  1-indexed
---@return integer|nil end_col    1-indexed inclusive
local function next_accent_macro(line, pos)
  local i = pos
  while i <= #line do
    local s = line:find("\\", i, true)
    if not s then return nil end
    local e = accent_macro_end(line, s)
    if e then return s, e end
    i = s + 1
  end
end

---Given an accent macro span [accent_s, accent_e], expand outward
---through preceding letters and through trailing letters / additional
---accent macros to produce the full word-like token.
---@return integer tok_start  1-indexed inclusive
---@return integer tok_end    1-indexed inclusive
local function expand_token(line, accent_s, accent_e)
  local tok_start = accent_s
  while tok_start > 1 and line:sub(tok_start - 1, tok_start - 1):match("%a") do
    tok_start = tok_start - 1
  end

  local tok_end = accent_e
  while tok_end < #line do
    local nxt = tok_end + 1
    local c = line:sub(nxt, nxt)
    if c:match("%a") then
      tok_end = nxt
    else
      local macro_end = accent_macro_end(line, nxt)
      if macro_end then
        tok_end = macro_end
      else
        break
      end
    end
  end

  return tok_start, tok_end
end

---Find every accented word token in a single line of text.  Pure --
---no buffer or treesitter required.  Tokens are emitted in order;
---overlapping tokens are not possible because expansion is greedy and
---we restart scanning past each consumed span.
---@param line string
---@return noethervim_tex.AccentLineToken[]
function M.find_tokens(line)
  local results = {}
  local pos = 1
  while pos <= #line do
    local accent_s, accent_e = next_accent_macro(line, pos)
    if not accent_s then break end
    local tok_s, tok_e = expand_token(line, accent_s, accent_e)
    local raw = line:sub(tok_s, tok_e)
    local decoded = decoder.decode(raw)
    if decoded then
      results[#results + 1] = {
        start_col = tok_s,
        end_col = tok_e,
        raw = raw,
        decoded = decoded,
      }
    end
    pos = tok_e + 1
  end
  return results
end

-- Treesitter context check: is the position inside an inline_formula,
-- displayed_equation, math_environment, line_comment, or block_comment?
-- Returns false (don't exclude) if the parser isn't available -- the
-- caller decides whether that's an issue.
local CONTEXT_EXCLUDE = {
  inline_formula     = true,
  displayed_equation = true,
  math_environment   = true,
  math_set           = true,
  line_comment       = true,
  block_comment      = true,
}

local function in_excluded_context(bufnr, row, col)
  local ok, node = pcall(vim.treesitter.get_node, {
    bufnr = bufnr,
    pos = { row, col },
    lang = "latex",
  })
  if not ok or not node then return false end
  local cur = node
  while cur do
    if CONTEXT_EXCLUDE[cur:type()] then return true end
    cur = cur:parent()
  end
  return false
end

---Scan a whole buffer for accented tokens.  Math regions and comments
---are excluded via treesitter.  If the latex parser isn't available
---the function still returns tokens (caller can decide to no-op via a
---health check or graceful-degrade flag).
---@param bufnr? integer  default current buffer
---@return noethervim_tex.AccentToken[]
function M.scan(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local results = {}

  -- Force a parse so subsequent get_node() calls return current state.
  -- get_node() on a never-parsed parser returns nil, which would make
  -- every token look like it's outside any context (silent false).
  pcall(function() vim.treesitter.get_parser(bufnr, "latex"):parse() end)

  for idx, line in ipairs(lines) do
    local row = idx - 1
    local tokens = M.find_tokens(line)
    for _, tok in ipairs(tokens) do
      local in_math = in_excluded_context(bufnr, row, tok.start_col - 1)
      results[#results + 1] = {
        range = { row, tok.start_col - 1, row, tok.end_col },
        raw = tok.raw,
        decoded = tok.decoded,
        is_in_math = in_math,
      }
    end
  end

  return results
end

return M
