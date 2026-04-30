# LaTeX accent spell-check — design spec

Status: **draft, pre-implementation**.
Owner: noethervim-tex (new module: `accent_spell`).
Conformance: `~/programming/custom_plugins/.claude/skills/writing-neovim-plugins/`.

## Problem

Vim's spell tokeniser splits words at non-letter characters, so `K\"ahler`
is seen as the fragments `K`, `ahler` — and the fragments get flagged as
misspellings on every LaTeX-encoded proper noun (`H\"older`, `Erd\H{o}s`,
`Poincar\'e`, `Schr\"odinger`, …).

Worse: with vimtex's `g:vimtex_syntax_conceal.accents` on (the default),
`\"o` becomes a 3-char `texCmdAccent` group whose **trailing letters are
also skipped by spell-check**. So a typo like `K\"ohler` (should be
`\"a`) silently passes — vim's syntax-aware spell tokeniser gives up on
text that lives in the shadow of a concealed accent.

The current workaround is fragment entries in `spell/en.utf-8.add`
(`ahler`, `Erd`, `\'etal\'e`). They accept *any* word ending in the
fragment (`xahler`, `yErdy`) and don't catch trailing typos either.

## Goals

1. **No false positives** on common LaTeX-accented proper nouns.
2. **Whole-token marking** — diagnostic spans the entire `K\"ohler`,
   not a fragment. Solves the trailing-text gap.
3. **Easy to add words** — one keystroke or one command.
4. **Easy to mark wrong** — same.
5. **Conceal-agnostic** — works whether `\"a` is concealed or not.
6. **Cheap** — incremental, debounced, no lag on a 5k-line `.tex`.

## Non-goals

- Spell-checking inside math regions (already `@NoSpell`).
- Replacing vim's native spell-check; we sit beside it.
- Grammar / style. Just spelling of accented tokens.
- Multi-language fallback. Future work.

## Architecture

Detection model: **diagnostics, not syntax.** Scan the buffer for
LaTeX-accent tokens, decode each to its Unicode form, ask vim's spell
machinery whether the decoded form is a word, attach a `vim.diagnostic`
over the token range when it isn't.

Why diagnostics:
- Bypasses vim's syntax-aware spell tokeniser → solves trailing-text gap.
- Whole-token range comes free.
- Pluggable via `vim.diagnostic` — works with `:Trouble`, signcolumn,
  virtual_text, code-actions out of the box.

Why not a syntax overlay:
- Curated allowlist is brittle and never finishes growing.
- Vim's spell engine ignores `@Spell` cluster membership for letters
  inside `texCmdAccent` conceal regions.

Scanner backend: **treesitter** (latex parser). The plugin already ships
queries under `queries/latex/`; this is one more. Treesitter gives clean
node ranges and reliable math/comment exclusion. Fail gracefully if the
parser is missing (health check warns; no diagnostics emitted).

## Components

```
lua/noethervim-tex/accent_spell/
├── init.lua          -- M.setup, M.refresh, M.add, M.mark_wrong, M.suggest, M.is_enabled
├── decoder.lua       -- (accent, letter) → Unicode; M.decode(raw) → unicode|nil
├── scanner.lua       -- treesitter-driven token finder; M.scan(bufnr) → list
├── diagnostics.lua   -- namespace, refresh/clear, debouncer
├── commands.lua      -- :NoetherTexAccent* registration
└── default_words.lua -- list of common Unicode forms shipped with the plugin

queries/latex/
└── accent_spell.scm  -- treesitter query for accent-bearing word tokens

plugin/noethervim_tex.lua    (NEW)
                      -- vim.g.loaded_ guard, <Plug> mappings, command stubs.
                         setup() in lua/ patches defaults; init lives here.

spell/
├── en.utf-8.add        (existing math vocab, untouched apart from
│                        removing the three fragment hacks in phase 5)
└── accent_names.utf-8.add  (NEW: shipped Unicode dict for proper nouns)
```

The new `plugin/noethervim_tex.lua` is required by the writing-neovim-plugins
skill — currently noethervim-tex auto-inits from inside `setup()`, which the
skill flags as a divergence. We fix that as a sub-deliverable of phase 3.

### `decoder.lua`

Single source of truth for LaTeX-accent → Unicode mapping. Inverts
vimtex's `s:map_accents`.

```lua
---@class noethervim-tex.AccentDecoder
local M = {}

---Decode a raw LaTeX-accented token to its Unicode form.
---@param raw string  e.g. "K\\\"ahler", "Erd\\H{o}s"
---@return string|nil  Unicode form, or nil if any embedded accent is
---unrecognised (caller should not flag the token in that case).
function M.decode(raw) ... end

---Vim regex matching any accent macro (no surrounding letters). Used by
---the scanner to detect candidate tokens before passing them through
---decode().
M.accent_regex = [[\\\(["'`^=.~]\|[Hbcdvurkt]{\)]]
```

Cases handled:
- Bare accent + letter: `\"a` → `ä`
- Braced: `\"{a}` → `ä`
- Letter-accent (braces required): `\H{o}` → `ő`, `\v{c}` → `č`
- Multiple accents: `r\'esum\'e` → `résumé`
- Dotless: `\"{\i}` → `ï`

Decoder is data-driven (a Lua table); adding accents is two lines.

### `scanner.lua`

```lua
---@class noethervim-tex.AccentToken
---@field range { [1]: integer, [2]: integer, [3]: integer, [4]: integer } -- start_row, start_col, end_row, end_col (0-indexed, byte cols)
---@field raw string
---@field decoded string
---@field is_in_math boolean

---@param bufnr integer
---@return noethervim-tex.AccentToken[]
function M.scan(bufnr) ... end
```

Implementation: treesitter query against the latex parser, capturing
sequences of letter+command nodes that compose an accented word. Math
context check via the same parser (`generic_environment` with names
`equation`/`align`/etc., or inline math nodes) — we filter those out.

Falls back to a no-op (returns `{}`) if `vim.treesitter.get_parser(bufnr, "latex")`
fails. Health check surfaces this.

### `diagnostics.lua`

Owns one `vim.api.nvim_create_namespace("noethervim_tex_accent_spell")`.

```lua
---@param bufnr integer
function M.refresh(bufnr) ... end  -- scan, decode, spellbadword, set diagnostics

---@param bufnr integer
function M.clear(bufnr) ... end
```

Diagnostic shape:
```lua
{
  lnum = ..., col = ...,            -- start (0-indexed)
  end_lnum = ..., end_col = ...,
  severity = vim.diagnostic.severity.INFO,
  source   = "noethervim-tex.accent-spell",
  message  = ('possible misspelling: %s'):format(decoded),
  user_data = { raw = raw, decoded = decoded },
}
```

Severity is **INFO** by default (visible in signcolumn / `:Trouble`,
not as alarming as WARN).

### `commands.lua`

Registered from `plugin/noethervim_tex.lua` (defer-required on first
call).

| Command | Arg | Action |
|---------|-----|--------|
| `:NoetherTexAccentSpell {enable\|disable\|toggle}` | — | per-buffer on/off |
| `:NoetherTexAccentAdd` | `[word]` | decode the cword (or arg), `:spellgood` the Unicode form, refresh |
| `:NoetherTexAccentMarkWrong` | `[word]` | decode, `:spellwrong` |
| `:NoetherTexAccentSuggest` | — | `vim.ui.select` of `spellsuggest()` results on the decoded form, replace token with re-encoded LaTeX form on confirm |

### `<Plug>` mappings (no default keymaps)

Per writing-neovim-plugins conventions, we ship `<Plug>` mappings and a
public Lua API; **no default keymaps**.

```lua
-- plugin/noethervim_tex.lua
vim.keymap.set("n", "<Plug>(noethervim-tex-accent-add)",
  function() require("noethervim-tex.accent_spell").add() end,
  { desc = "noethervim-tex: add accented word to spellfile" })

vim.keymap.set("n", "<Plug>(noethervim-tex-accent-mark-wrong)",
  function() require("noethervim-tex.accent_spell").mark_wrong() end,
  { desc = "noethervim-tex: mark accented word as misspelled" })

vim.keymap.set("n", "<Plug>(noethervim-tex-accent-suggest)",
  function() require("noethervim-tex.accent_spell").suggest() end,
  { desc = "noethervim-tex: replace accented token with a suggestion" })
```

Recommended bindings (documented in `:h noethervim-tex-accent-spell`,
not set by us):

```lua
-- in your config:
vim.keymap.set("n", "zG", "<Plug>(noethervim-tex-accent-add)",         { desc = "spell: add accented word" })
vim.keymap.set("n", "zW", "<Plug>(noethervim-tex-accent-mark-wrong)", { desc = "spell: mark accented word wrong" })
vim.keymap.set("n", "z=", "<Plug>(noethervim-tex-accent-suggest)",    { desc = "spell: suggest accented form" })
```

This satisfies both the convention (no surprise keymaps from a plugin)
and your workflow (`zG`/`zW` extending your existing `zg`/`zw` muscle
memory). The `<Plug>` indirection means we stay rebindable forever.

A future enhancement could ship a `setup({install_default_keymaps =
true})` opt — but per the skill, that's an explicit user opt-in, not the
default.

## Public API

```lua
---@class noethervim-tex.AccentSpellConfig
---@field enabled boolean                              -- default true
---@field severity integer                             -- vim.diagnostic.severity.*  (default INFO)
---@field debounce_ms integer                          -- default 250
---@field decoder_extras table<string, string>         -- {accent..letter -> unicode}
---@field auto_install_word_dict boolean               -- default true; mkspells the shipped accent_names list once

---@param opts? noethervim-tex.AccentSpellConfig
function require("noethervim-tex.accent_spell").setup(opts) end

---Force-rescan a buffer.
---@param bufnr? integer  default current
function require("noethervim-tex.accent_spell").refresh(bufnr) end

---Add the cword (decoded) to the user spellfile.
---@param word? string  override; default current cword
function require("noethervim-tex.accent_spell").add(word) end

---Mark the cword (decoded) as wrong.
---@param word? string
function require("noethervim-tex.accent_spell").mark_wrong(word) end

---Open suggestion picker over the cword.
function require("noethervim-tex.accent_spell").suggest() end

---@param bufnr? integer  default current
---@return boolean
function require("noethervim-tex.accent_spell").is_enabled(bufnr) end
```

`setup()` is wired through noethervim-tex's existing top-level
`setup()`:

```lua
require("noethervim-tex").setup({
  preamble_folder = ...,
  extra_snippet_paths = ...,
  textobjects = true,
  accent_spell = { enabled = true, severity = vim.diagnostic.severity.INFO },
})
```

## Word management — three layers

1. **User spellfile** (`stdpath("config")/spell/en.utf-8.add` etc.) —
   user's own additions, written by `:NoetherTexAccentAdd`. Authoritative.
2. **Shipped accent dictionary** (`spell/accent_names.utf-8.add`, NEW
   file in this plugin) — common Unicode proper nouns: Kähler, Hölder,
   Schrödinger, Möbius, Gödel, Erdős, Poincaré, Bézier, Bézout,
   Fréchet, naïve, étalé, résumé, Šostakovich, Łukasiewicz, …. Built
   into `.spl` via `mkspell` on plugin install (same mechanism as
   today's `en.utf-8.add` rebuild in NoetherVim's latex bundle).
3. **No fallback** — anything decoded but not in 1 or 2 → diagnostic.

The two `.add` files stay separate: `en.utf-8.add` is math *vocabulary*
(words like "abelian", "adjoint"), `accent_names.utf-8.add` is *names
that happen to need accents*. Different responsibilities, different
maintainers in the long run.

## Conformance to writing-neovim-plugins skill

| Rule | How we satisfy it |
|------|-------------------|
| Strict separation of init from setup | `plugin/noethervim_tex.lua` registers commands, autocmds, `<Plug>` mappings. `setup()` only patches defaults and (de)activates accent_spell |
| `vim.g.loaded_noethervim_tex` guard | Added in the new `plugin/` file |
| `<Plug>` mappings before keymaps | Explicit; no default keymaps shipped |
| LuaCATS on public API | All `M.*` annotated; the `accent_spell.AccentSpellConfig` and `AccentToken` classes documented |
| Vimdoc | `:h noethervim-tex-accent-spell` section appended to existing `doc/noethervim-tex.txt` |
| Health check | `lua/noethervim-tex/health.lua` (NEW or extended): treesitter parser presence, `.spl` build status, spellfile writeability |
| Augroup naming | `noethervim_tex_accent_spell`, `{ clear = true }`, every autocmd carries `desc` |
| `vim.notify` prefix | All notifications go `[noethervim-tex] …` |
| Tests | `tests/decoder_spec.lua`, `tests/scanner_spec.lua` (with a fixture .tex), `tests/diagnostics_spec.lua` (smoke). Plenary busted via `tests/run.sh` |

## Edge cases

| Case | Behaviour |
|------|-----------|
| `K\"ahler` | decode → `Kähler` → in shipped dict → no diagnostic |
| `Kähler` (Unicode) | vim spell finds it in shipped dict → no flag from us or from vim |
| `K\"ohler` (typo) | decode → `Köhler` → not in dict → INFO over the whole `K\"ohler` |
| `r\'esum\'e` | decode → `résumé` → in shipped dict → ok |
| `\"omega` in math | scanner sees math context → skipped |
| `% K\"ahler` in comment | scanner sees comment context → skipped |
| `K\"yhler` (no decode for `\"y`) | decoder returns nil → no diagnostic (conservative) |
| `\foo{bar}` | regex doesn't match (only accent macros), nothing happens |
| `K\"a hler` (whitespace-broken) | not a single token; vim's normal spell handles each piece |
| Multi-accent `\'eta\'e` | decoder loops; multi-pass replacement handled |

## Migration of fragment hacks

Phase 5 deliverable.

1. Remove from `spell/en.utf-8.add`: `\'etal\'e` (line 2), `ahler`
   (line 25), `Erd` (line 301).
2. Add to the new `spell/accent_names.utf-8.add`: Unicode forms for
   each removed fragment (`étalé`, `Kähler` — already covered, `Erdős`
   — already covered).
3. Bump NoetherVim's latex bundle to invalidate stale `.spl` files on
   first load (`fs_unlink` the `.spl` if older than the `.add`, then let
   the existing mkspell rebuild logic regenerate).

## Implementation phases / PR plan

| PR | Phase | Scope | Deliverable | Reviewable in |
|----|-------|-------|-------------|---------------|
| 1  | 1     | Decoder + tests | `decoder.lua`, full `tests/decoder_spec.lua` covering every accent in vimtex's table | < 30 min |
| 2  | 2     | Scanner + treesitter query + tests | `scanner.lua`, `queries/latex/accent_spell.scm`, `tests/scanner_spec.lua` with a fixture `.tex`, manual smoke shows token detection | < 60 min |
| 3  | 3,4   | Diagnostics + commands + `<Plug>` mappings + `plugin/noethervim_tex.lua` reorg + autocmd wiring | typing in a buffer produces / clears INFO diagnostics; commands and Plug mappings work; setup() pattern conforms to skill | medium PR, integration-heavy |
| 4  | 5,6   | Shipped accent dict + spellfile migration + vimdoc + README + health check | fresh install with no user words: 20+ listed names produce no diagnostics; old fragments gone; `:h noethervim-tex-accent-spell` exists | small PR, mostly content |

PRs 1 and 2 land no user-visible behaviour and can ship back-to-back.
PR 3 is the activation. PR 4 is the polish + cleanup.

## Reference

- Skill: `~/programming/custom_plugins/.claude/skills/writing-neovim-plugins/`
- vimtex accent table: `autoload/vimtex/syntax/core.vim` `s:map_accents`,
  lines ~2415-2470.
- Fragment workaround precedent in this repo: `spell/en.utf-8.add` lines
  2, 25, 301.
- Existing spell-file build hook: NoetherVim `lua/noethervim/bundles/languages/latex.lua`
  lines 314-326.
