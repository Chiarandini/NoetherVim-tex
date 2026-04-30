-- noethervim-tex.accent_spell.scanner spec.

local scanner = require("noethervim-tex.accent_spell.scanner")

local function tokens(line)
  -- Drop start/end cols for compactness when we only care about content.
  local out = {}
  for _, t in ipairs(scanner.find_tokens(line)) do
    out[#out + 1] = { raw = t.raw, decoded = t.decoded }
  end
  return out
end

describe("scanner.find_tokens", function()
  describe("single accent tokens", function()
    it('finds K\\"ahler as one token', function()
      local got = tokens('K\\"ahler')
      assert.are.same({ { raw = 'K\\"ahler', decoded = "Kähler" } }, got)
    end)
    it("finds Erd\\H{o}s as one token", function()
      local got = tokens("Erd\\H{o}s")
      assert.are.same({ { raw = "Erd\\H{o}s", decoded = "Erdős" } }, got)
    end)
    it("finds Poincar\\'e as one token", function()
      local got = tokens("Poincar\\'e")
      assert.are.same({ { raw = "Poincar\\'e", decoded = "Poincaré" } }, got)
    end)
    it('finds K\\"{a}hler (braced) as one token', function()
      local got = tokens('K\\"{a}hler')
      assert.are.same({ { raw = 'K\\"{a}hler', decoded = "Kähler" } }, got)
    end)
    it("captures correct byte ranges", function()
      local toks = scanner.find_tokens('hello K\\"ahler world')
      assert.are.equal(1, #toks)
      assert.are.equal(7, toks[1].start_col)
      assert.are.equal(14, toks[1].end_col)  -- "K\"ahler" = 8 chars; 7..14 inclusive
    end)
  end)

  describe("multi-accent tokens", function()
    it("captures r\\'esum\\'e as one token", function()
      local got = tokens("r\\'esum\\'e")
      assert.are.same({ { raw = "r\\'esum\\'e", decoded = "résumé" } }, got)
    end)
    it("captures \\'etal\\'e as one token", function()
      local got = tokens("\\'etal\\'e")
      assert.are.same({ { raw = "\\'etal\\'e", decoded = "étalé" } }, got)
    end)
  end)

  describe("multiple tokens on a line", function()
    it("finds two separate tokens", function()
      local got = tokens('K\\"ahler and H\\"older')
      assert.are.same({
        { raw = 'K\\"ahler', decoded = "Kähler" },
        { raw = 'H\\"older', decoded = "Hölder" },
      }, got)
    end)
    it("finds three with mixed forms", function()
      local got = tokens("K\\\"ahler, Erd\\H{o}s, Poincar\\'e.")
      assert.are.same({
        { raw = 'K\\"ahler',  decoded = "Kähler" },
        { raw = "Erd\\H{o}s", decoded = "Erdős" },
        { raw = "Poincar\\'e", decoded = "Poincaré" },
      }, got)
    end)
  end)

  describe("token at line edges", function()
    it("token at start of line", function()
      local got = tokens("\\\"ahler is here")
      assert.are.equal('\\"ahler', got[1].raw)
    end)
    it("token at end of line", function()
      local got = tokens("here is K\\\"ahler")
      assert.are.equal('K\\"ahler', got[1].raw)
    end)
    it("entire line is a single token", function()
      local got = tokens("K\\\"ahler")
      assert.are.equal('K\\"ahler', got[1].raw)
    end)
  end)

  describe("non-accent backslash macros", function()
    it("ignores \\hat{x}", function()
      assert.are.same({}, tokens("the \\hat{x} symbol"))
    end)
    it("ignores \\section{intro}", function()
      assert.are.same({}, tokens("\\section{Introduction}"))
    end)
    it("ignores \\\\ (line break)", function()
      assert.are.same({}, tokens("end of line \\\\"))
    end)
    it("ignores plain words with no accent", function()
      assert.are.same({}, tokens("Kahler manifold"))
    end)
    it("ignores empty line", function()
      assert.are.same({}, tokens(""))
    end)
  end)

  describe("malformed accents are not flagged", function()
    it("ignores trailing backslash", function()
      assert.are.same({}, tokens("foo\\"))
    end)
    it("ignores unmatched brace", function()
      assert.are.same({}, tokens("K\\\"{a"))
    end)
    it("ignores accent over digit", function()
      assert.are.same({}, tokens("K\\\"5"))
    end)
  end)

  describe("punctuation and whitespace boundaries", function()
    it("punctuation breaks the token", function()
      local got = tokens("K\\\"ahler,foo")
      assert.are.equal('K\\"ahler', got[1].raw)
    end)
    it("hyphen breaks the token", function()
      local got = tokens("K\\\"ahler-Einstein")
      assert.are.equal('K\\"ahler', got[1].raw)
    end)
    it("token surrounded by parens", function()
      local got = tokens("(K\\\"ahler)")
      assert.are.equal('K\\"ahler', got[1].raw)
    end)
  end)

  describe("accent-then-letter without preceding letters", function()
    it("\\\"omega is a token (would be ωmega-ish)", function()
      -- \"o decodes to ö; trailing "mega" gets pulled in. The decoded
      -- "ömega" is not a real word, but the scanner's job is just to
      -- find candidates. Diagnostics layer flags it.
      local got = tokens("\\\"omega")
      assert.are.equal('\\"omega', got[1].raw)
      assert.are.equal("ömega", got[1].decoded)
    end)
  end)

  describe("real-world fixture", function()
    local line = "The K\\\"ahler manifold and H\\\"older inequality, "
              .. "with Erd\\H{o}s, Poincar\\'e, and Schr\\\"odinger."
    it("finds all five names", function()
      local got = tokens(line)
      assert.are.equal(5, #got)
      assert.are.equal("Kähler",     got[1].decoded)
      assert.are.equal("Hölder",     got[2].decoded)
      assert.are.equal("Erdős",      got[3].decoded)
      assert.are.equal("Poincaré",   got[4].decoded)
      assert.are.equal("Schrödinger", got[5].decoded)
    end)
  end)
end)

describe("scanner.scan (buffer-level)", function()
  local function setup_buf(lines)
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.api.nvim_buf_set_option(buf, "filetype", "tex")
    vim.api.nvim_set_current_buf(buf)
    -- Force a treesitter parse so context check works.
    pcall(vim.treesitter.get_parser, buf, "latex")
    return buf
  end

  it("returns rows correctly", function()
    local buf = setup_buf({
      'K\\"ahler manifold.',
      'Erd\\H{o}s number.',
    })
    local got = scanner.scan(buf)
    assert.are.equal(2, #got)
    assert.are.equal(0, got[1].range[1])
    assert.are.equal(1, got[2].range[1])
    vim.api.nvim_buf_delete(buf, { force = true })
  end)

  it("range cols are 0-indexed end-exclusive", function()
    local buf = setup_buf({ 'X K\\"ahler X' })
    local got = scanner.scan(buf)
    assert.are.equal(1, #got)
    assert.are.equal(2, got[1].range[2])   -- 0-indexed start of "K\""
    assert.are.equal(10, got[1].range[4])  -- 0-indexed end-exclusive after "r"
    vim.api.nvim_buf_delete(buf, { force = true })
  end)

  it("flags is_in_math for tokens inside inline math", function()
    local buf = setup_buf({ '$X = K\\"ahler$' })
    local got = scanner.scan(buf)
    if vim.treesitter.language.add and vim.treesitter.language.add("latex") then
      assert.are.equal(1, #got)
      assert.is_true(got[1].is_in_math)
    end
    vim.api.nvim_buf_delete(buf, { force = true })
  end)

  it("flags is_in_math for tokens inside line comments", function()
    local buf = setup_buf({ '% K\\"ahler in a comment' })
    local got = scanner.scan(buf)
    if vim.treesitter.language.add and vim.treesitter.language.add("latex") then
      assert.are.equal(1, #got)
      assert.is_true(got[1].is_in_math)
    end
    vim.api.nvim_buf_delete(buf, { force = true })
  end)

  it("does not flag is_in_math for tokens in plain text", function()
    local buf = setup_buf({ 'K\\"ahler manifold.' })
    local got = scanner.scan(buf)
    if vim.treesitter.language.add and vim.treesitter.language.add("latex") then
      assert.are.equal(1, #got)
      assert.is_false(got[1].is_in_math)
    end
    vim.api.nvim_buf_delete(buf, { force = true })
  end)
end)
