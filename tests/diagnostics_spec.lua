-- noethervim-tex.accent_spell integration smoke tests.
--
-- Exercises the diagnostics module + the public API that wraps it.
-- We use vim's stock en_us spellfile (always available in headless
-- nvim) as the dictionary, so behaviour here matches a fresh install
-- with no shipped accents dict yet.

local accent = require("noethervim-tex.accent_spell")
local diagnostics = require("noethervim-tex.accent_spell.diagnostics")

local function setup_buf(lines)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, "filetype", "tex")
  vim.api.nvim_set_current_buf(buf)
  vim.opt_local.spelllang = "en_us"
  vim.opt_local.spell = true
  return buf
end

local function get_diags(buf)
  return vim.diagnostic.get(buf, { namespace = diagnostics.namespace() })
end

describe("accent_spell.refresh", function()
  before_each(function()
    accent.setup({ enabled = true })
  end)

  it("emits a diagnostic for an undecodable name not in the dict", function()
    local buf = setup_buf({ "K\\\"ahler manifold." })
    accent.refresh(buf)
    local diags = get_diags(buf)
    -- Kähler is not in vim's en_us dict, so we expect one diagnostic.
    assert.are.equal(1, #diags)
    assert.are.equal("Kähler", diags[1].user_data.decoded)
    assert.matches("Kähler", diags[1].message)
    vim.api.nvim_buf_delete(buf, { force = true })
  end)

  it("emits no diagnostic when decoded form is in the spellfile", function()
    local buf = setup_buf({ "Caf\\'e here." })
    -- Add the decoded form to the user's session spellfile.
    vim.cmd("silent! spellgood! Café")
    accent.refresh(buf)
    local diags = get_diags(buf)
    assert.are.equal(0, #diags)
    vim.api.nvim_buf_delete(buf, { force = true })
  end)

  it("clears diagnostics when feature disabled mid-session", function()
    local buf = setup_buf({ "K\\\"ahler form." })
    accent.refresh(buf)
    assert.is_true(#get_diags(buf) > 0)
    accent.disable(buf)
    assert.are.equal(0, #get_diags(buf))
    vim.api.nvim_buf_delete(buf, { force = true })
  end)

  it("skips tokens inside math regions", function()
    local buf = setup_buf({ "$X = K\\\"ahler$" })
    -- Force ts parse for context check.
    pcall(function() vim.treesitter.get_parser(buf, "latex"):parse() end)
    accent.refresh(buf)
    local diags = get_diags(buf)
    assert.are.equal(0, #diags)
    vim.api.nvim_buf_delete(buf, { force = true })
  end)

  it("skips tokens inside line comments", function()
    local buf = setup_buf({ "% K\\\"ahler in comment" })
    pcall(function() vim.treesitter.get_parser(buf, "latex"):parse() end)
    accent.refresh(buf)
    local diags = get_diags(buf)
    assert.are.equal(0, #diags)
    vim.api.nvim_buf_delete(buf, { force = true })
  end)

  it("range covers the whole LaTeX-encoded token", function()
    local buf = setup_buf({ 'X K\\"ahler X' })
    accent.refresh(buf)
    local diags = get_diags(buf)
    assert.are.equal(1, #diags)
    -- "K\"ahler" spans cols 2 (start of K) to 10 (end of r) in 0-indexed
    -- byte positions; end is exclusive.
    assert.are.equal(2, diags[1].col)
    assert.are.equal(10, diags[1].end_col)
    vim.api.nvim_buf_delete(buf, { force = true })
  end)

  it("uses configured severity (INFO by default)", function()
    local buf = setup_buf({ "K\\\"ahler ." })
    accent.refresh(buf)
    local diags = get_diags(buf)
    assert.are.equal(vim.diagnostic.severity.INFO, diags[1].severity)
    vim.api.nvim_buf_delete(buf, { force = true })
  end)

  it("respects severity override from setup()", function()
    accent.setup({ severity = vim.diagnostic.severity.WARN })
    local buf = setup_buf({ "K\\\"ahler ." })
    accent.refresh(buf)
    local diags = get_diags(buf)
    assert.are.equal(vim.diagnostic.severity.WARN, diags[1].severity)
    vim.api.nvim_buf_delete(buf, { force = true })
  end)
end)

describe("accent_spell native-spell suppression (extmarks)", function()
  before_each(function()
    accent.setup({ enabled = true })
  end)

  local function suppress_extmarks(buf)
    return vim.api.nvim_buf_get_extmarks(
      buf, diagnostics.suppress_namespace(), 0, -1, { details = true })
  end

  it("drops a spell=false extmark over every decoded token", function()
    local buf = setup_buf({ "K\\\"ahler and Erd\\H{o}s." })
    accent.refresh(buf)
    local marks = suppress_extmarks(buf)
    assert.are.equal(2, #marks)
    -- Each extmark must carry spell = false in its details.
    for _, m in ipairs(marks) do
      assert.is_false(m[4].spell)
    end
    vim.api.nvim_buf_delete(buf, { force = true })
  end)

  it("extmark range matches the token range", function()
    local buf = setup_buf({ 'X K\\"ahler X' })
    accent.refresh(buf)
    local marks = suppress_extmarks(buf)
    assert.are.equal(1, #marks)
    -- Extmark format: { id, row, col, details }
    assert.are.equal(0, marks[1][2])         -- start row
    assert.are.equal(2, marks[1][3])         -- start col (start of K)
    assert.are.equal(0, marks[1][4].end_row)
    assert.are.equal(10, marks[1][4].end_col) -- end col after r
    vim.api.nvim_buf_delete(buf, { force = true })
  end)

  it("clears suppressions when the feature is disabled", function()
    local buf = setup_buf({ "K\\\"ahler form." })
    accent.refresh(buf)
    assert.is_true(#suppress_extmarks(buf) > 0)
    accent.disable(buf)
    assert.are.equal(0, #suppress_extmarks(buf))
    vim.api.nvim_buf_delete(buf, { force = true })
  end)

  it("re-creates suppressions on subsequent refresh", function()
    local buf = setup_buf({ "K\\\"ahler form." })
    accent.refresh(buf)
    local first = #suppress_extmarks(buf)
    accent.refresh(buf)
    assert.are.equal(first, #suppress_extmarks(buf))
    vim.api.nvim_buf_delete(buf, { force = true })
  end)

  it("suppresses native spell even when our diagnostic also fires", function()
    -- Köhler is a real-world undecodable-as-correct case; both layers
    -- should fire (suppress + diagnostic).
    local buf = setup_buf({ "K\\\"ohler manifold." })
    accent.refresh(buf)
    assert.are.equal(1, #suppress_extmarks(buf))
    assert.are.equal(1, #get_diags(buf))
    vim.api.nvim_buf_delete(buf, { force = true })
  end)
end)

describe("accent_spell.is_enabled", function()
  it("returns global default when no override", function()
    accent.setup({ enabled = true })
    local buf = setup_buf({ "K\\\"ahler." })
    assert.is_true(accent.is_enabled(buf))
    vim.api.nvim_buf_delete(buf, { force = true })
  end)

  it("respects per-buffer disable override", function()
    accent.setup({ enabled = true })
    local buf = setup_buf({ "K\\\"ahler." })
    accent.disable(buf)
    assert.is_false(accent.is_enabled(buf))
    vim.api.nvim_buf_delete(buf, { force = true })
  end)

  it("respects global disable", function()
    accent.setup({ enabled = false })
    local buf = setup_buf({ "K\\\"ahler." })
    assert.is_false(accent.is_enabled(buf))
    vim.api.nvim_buf_delete(buf, { force = true })
  end)
end)

describe("accent_spell.config()", function()
  it("returns a copy with applied opts", function()
    accent.setup({ severity = vim.diagnostic.severity.WARN, debounce_ms = 500 })
    local cfg = accent.config()
    assert.are.equal(vim.diagnostic.severity.WARN, cfg.severity)
    assert.are.equal(500, cfg.debounce_ms)
    -- Mutating the returned table must not affect internal state.
    cfg.severity = 999
    assert.are.equal(vim.diagnostic.severity.WARN, accent.config().severity)
  end)
end)

describe("accent_spell.add (no-buffer-token path)", function()
  it("decodes a passed word and silent-writes to spellfile", function()
    accent.setup({ enabled = true })
    local buf = setup_buf({ "irrelevant" })
    -- M.add() with explicit word skips the cursor-token lookup.
    assert.has_no.errors(function()
      accent.add("Br\\'ezis")
    end)
    -- Verify the word is now considered good.
    assert.are.equal("", vim.fn.spellbadword("Brézis")[1])
    vim.api.nvim_buf_delete(buf, { force = true })
  end)
end)
