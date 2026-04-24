# noethervim-tex

A LaTeX companion plugin for Neovim, built for mathematical writing. Provides context-aware LuaSnip snippets, treesitter textobject navigation, a preamble completion source, custom syntax highlights, and a spell dictionary of 900+ mathematical terms.

Standalone by design, but integrates seamlessly with [NoetherVim](https://github.com/Chiarandini/NoetherVim) as part of its `latex` bundle.

---

## Philosophy

- **Mathematical writing first.** Snippets, abbreviations, and textobjects are tailored to theorem-proof workflows — definitions, propositions, lemmas, corollaries, examples, and exercises.
- **Context-aware.** Snippets expand only where they make sense: math symbols in math zones, text formatting in text zones, preamble templates outside `\begin{document}`.
- **No extra dependencies.** Treesitter textobjects use native `vim.treesitter` — no `nvim-treesitter-textobjects` plugin required.
- **Extensible.** Write your own snippets using the public helper API, or add extra snippet directories via configuration.

---

## Requirements

- Neovim >= 0.10
- [LuaSnip](https://github.com/L3MON4D3/LuaSnip) — snippet engine
- [VimTeX](https://github.com/lervag/vimtex) — environment and math zone detection
- Treesitter `latex` parser — for textobject navigation and syntax highlights

Optional:
- [blink.cmp](https://github.com/Saghen/blink.cmp) — for the preamble completion source

---

## Installation

With [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{ "Chiarandini/noethervim-tex",
  ft = "tex",
  opts = {},
}
```

If using NoetherVim, the plugin is already included in the `latex` bundle — no extra setup needed.

---

## Configuration

```lua
require("noethervim-tex").setup({
  preamble_folder     = "~/my/preambles/",      -- default: stdpath("config")/preamble/
  extra_snippet_paths = { "~/shared-snippets/" },-- additional LuaSnip load paths
  textobjects         = true,                    -- treesitter navigation (default: true)
})
```

Or via lazy.nvim `opts`:

```lua
{ "Chiarandini/noethervim-tex", opts = {
    preamble_folder = "~/my/preambles/",
    textobjects = false,
} }
```

| Option | Type | Default | Description |
|---|---|---|---|
| `preamble_folder` | string | `stdpath("config")/preamble/` | Directory containing `.tex` preamble files |
| `extra_snippet_paths` | table | `{}` | Additional directories for LuaSnip to load |
| `textobjects` | boolean | `true` | Enable treesitter textobject keymaps |

---

## Features

### Treesitter textobject navigation

Jump between LaTeX structures in normal mode. All mappings are buffer-local to `tex`/`latex` filetypes.

| Keymap | Description |
|---|---|
| `]g` / `[g` | Next / prev theorem environment (defn, thm, prop, lem, cor) |
| `]p` / `[p` | Next / prev `\begin{Proof}` |
| `]P` / `[P` | Next / prev `\end{Proof}` |
| `]x` / `[x` | Next / prev `\begin{example}` |
| `]X` / `[X` | Next / prev `\end{example}` |
| `]c` / `[c` | Next / prev chapter |

Jumps are added to the jumplist, so `<C-o>` returns to the previous position.

### Preamble completion (blink.cmp)

Type `@` at the start of a line outside `\begin{document}` to trigger completion of preamble file names from your configured `preamble_folder`. Selecting an item inserts the filename (without `.tex`).

### Treesitter highlights

Custom highlight queries for:
- Theorem environment tags (defn, prop, thm, lem, cor, titledBox, example)
- Mismatched `}` in `\frac{}{}` arguments (highlighted as error)

### Spell dictionary

Ships `spell/en.utf-8.add` with 900+ mathematical and academic terms (homomorphism, Noetherian, cohomology, etc.) so they are not flagged by spell check.

---

## Snippets

All snippets are LuaSnip snippets loaded from the plugin's `LuaSnip/tex/` directory. They are organized into five files by category. Many support visual selection — select text, press the snippet trigger, and the selection wraps into the expanded snippet.

Snippets are either **manual** (expand with the LuaSnip expand key) or **auto** (expand immediately when the trigger is typed in the correct context).

### Environments

Structured LaTeX environments with auto-generated labels and reference tags.

**Manual triggers** (`:` prefix):

| Trigger | Expands to |
|---|---|
| `:thm <title>` | Theorem with label, optional Proof block |
| `:defn <title>` | Definition with label, index entry |
| `:prop <title>` | Proposition with label, Proof block |
| `:cor <title>` | Corollary with label, Proof block |
| `:lem <title>` | Lemma with label, Proof block |
| `:example <title>` | Example with label |
| `:exercise` | Exercise with Answer block |
| `:box <title>` | TitledBox with label |
| `:<envname>` | Generic `\begin{<envname>}...\end{<envname>}` |

**Auto triggers**:

| Trigger | Expands to |
|---|---|
| `ENV` | Generic `\begin{env}...\end{env}` |
| `nn` | equation environment |
| `EAS` | align* environment |
| `EEN` | enumerate environment |
| `EEE` | equivEnumerate environment |
| `EIT` | itemize environment |
| `FIG` | figure with `\includegraphics` |
| `<N>SFIG` | N subfigures inside a figure (e.g. `3SFIG`) |

### Math

Active only in math zones. All auto triggers unless noted.

**Fractions and operators**:

| Trigger | Output | Notes |
|---|---|---|
| `ff` | `\frac{}{}` | manual |
| `FF` | `\frac{}{}` | auto, requires non-alpha prefix |
| `//` | `\frac{}{}` | auto |
| `pf` | `\frac{\partial}{\partial}` | partial fraction |
| `pp` | `\partial` | |
| `DF` | `\diff` | |
| `dV` | `\dv{}` | |
| `der` | derivative evaluated at point | |
| `ee` | `e^{}` | requires non-alpha prefix |
| `exp` | `exp()` | requires non-alpha prefix |
| `intinf` | `\int_{-\infty}^{\infty}` | |

**Delimiters**:

| Trigger | Output |
|---|---|
| `((` | `\left( ... \right)` |
| `[[` | `\left[ ... \right]` |
| `{{` | `\left\{ ... \right\}` or `\set{}{}` (choice) |
| `\|\|` | `\left\| ... \right\|` |
| `<<` | `\langle ... \rangle` |

**Decorations**:

| Trigger | Output |
|---|---|
| `BB` | `\overline{}` |
| `HH` | `\hat{}` |
| `WH` | `\widehat{}` |
| `WT` | `\widetilde{}` |
| `TL` | `\tilde{}` |
| `UU` | `\underline{}` |
| `TT` | `\text{}` |

**Arrows**:

| Trigger | Output | Name |
|---|---|---|
| `->` | `\to` | |
| `-x>` | `\xrightarrow{}` | labeled arrow |
| `-h>` | `\hookrightarrow` | injection |
| `-2>` | `\twoheadrightarrow` | surjection |
| `-e>` | `\rightrightarrows` | equalizer |
| `-d>` | `\dashrightarrow` | rational map |
| `!>` | `\mapsto` | |

**Symbols and operators**:

| Trigger | Output |
|---|---|
| `cc` | `\subseteq` |
| `SS` | `\supseteq` |
| `CC` | `\circ` |
| `00` | `\emptyset` |
| `BH` | `\backslash` |
| `WW` | `\wedge` |
| `BL` | `\bullet` |
| `==` | `&=` (in align) |

**Sub/superscripts**:

| Trigger | Output |
|---|---|
| `__` | `_{}` |
| `^^` | `^{}` |

**Other**:

| Trigger | Output |
|---|---|
| `kk` | `\[ ... \]` display math |
| `mm` | `$ ... $` inline math (in text) |
| `qtq` | `\qquad \text{} \qquad` |
| `QLQ` | `\qquad\LRw\qquad` |

**Matrices** (regex triggers):

| Trigger | Output |
|---|---|
| `mat:MxN` | M-by-N matrix (e.g. `bmat:3x2`) |
| `mat:N` | N-by-N square matrix (e.g. `pmat:4`) |

Prefix with `b`, `B`, `p`, `v`, or `V` for bmatrix, Bmatrix, pmatrix, vmatrix, Vmatrix. Append `a` for augmented matrices.

### Text formatting

Active in text zones. All manual triggers.

| Trigger | Output |
|---|---|
| `i` | `\emph{}` |
| `b` | `\textbf{}` |
| `bi` | `\textbf{\emph{}}` |
| `ib` | `\emph{\textbf{}}` |
| `fn` | `\footnote{}` |
| ` `` ` | ` ``...'' ` (quotation, auto) |

### Document structure

Auto triggers for sectioning commands with optional labels (cycle with choice node).

| Trigger | Output |
|---|---|
| `PART` | `\part{}` |
| `CHA` | `\chapter{}` |
| `SSE` | `\section{}` |
| `SSS` | `\subsection{}` |
| `SS2` | `\subsubsection{}` |
| `SS*` | `\subsection*{}` |
| `RED` | `\textcolor{red}{}` |
| `GREEN` | `\textcolor{green}{}` |
| `href` | `\href{url}{display}` (manual) |
| `ph` | `\placeholder` (manual) |

### Text abbreviations

Auto-expanding abbreviations for common mathematical phrases.

| Trigger | Expands to |
|---|---|
| `tfae` / `Tfae` / `TFAE` | (The/the) following are equivalent |
| `iff` | if and only if (or `\text{ if and only if }` in math) |
| `wrt` | with respect to |
| `wlog` / `WLOG` | (Without/without) loss of generality |
| `ftsoc` / `FTSOC` | (For/for) the sake of contradiction |
| `st ` | such that |
| `otoh` / `OTOH` | (On/on) the other hand |
| `LHS` / `RHS` | left/right hand side |
| `SES` / `LES` / `EES` | short/long/exact sequence |
| `fg` | finitely generated |
| `fdim` | finite dimensional |
| `fdvsp` | finite dimensional vector space |
| `ndvsp` | $n$ dimensional vector space |
| `VSP` / `IPSP` | vector space / inner product space |
| `awsts` | as we sought to show |
| `ctp` | completing the proof |

---

## Writing custom snippets

Create `.lua` files in `~/.config/nvim/LuaSnip/tex/` (or wherever your LuaSnip user snippets live). They are auto-loaded alongside the plugin's built-in snippets.

Access the helper API:

```lua
local helper = require("noethervim-tex").luasnip_helper
local tex_utils = helper.tex_utils
local get_visual = helper.get_visual_node
```

**Environment detection** (`tex_utils`):

| Function | Description |
|---|---|
| `in_mathzone()` | Inside a math zone |
| `in_text()` | Inside document, outside math |
| `in_document()` | Inside `\begin{document}` |
| `in_preamble()` | Outside document, at line start |
| `in_env(name)` | Inside a specific environment |
| `in_comment()` | Inside a comment |
| `in_equation()` | Inside equation environment |
| `in_align()` | Inside align or align* |
| `in_itemize()` | Inside itemize |
| `in_cases()` | Inside cases |
| `in_tikz()` | Inside tikzpicture |

**Visual selection helpers**:

| Function | Description |
|---|---|
| `get_visual_node()` | Returns visual selection as text, or empty insert node |
| `get_visual_insert_node()` | Returns insert node pre-filled with visual selection |
| `get_visual_space_insert_node()` | Same, with leading whitespace trimmed |

**Other helpers**:

| Function | Description |
|---|---|
| `mat(args, snip)` | Generate M-by-N matrix nodes |
| `square_mat(args, snip)` | Generate N-by-N matrix nodes |
| `titlecase(str)` | Convert string to title case |
| `makeRefTag(str)` | Generate abbreviated reference labels |
| `subfigures(args, snip)` | Generate N subfigure nodes |
| `in_latex()` | Detect LaTeX math in non-LaTeX files (treesitter) |

---

## Structure

```
noethervim-tex/
├── lua/noethervim-tex/
│   ├── init.lua                  <- setup, config, public API
│   ├── luasnip_helper.lua        <- shared snippet utilities
│   ├── treesitter_textobjects.lua<- navigation keymaps
│   └── sources/
│       └── preambles.lua         <- blink.cmp preamble source
├── LuaSnip/tex/
│   ├── math.lua                  <- math mode snippets
│   ├── environments.lua          <- environment snippets
│   ├── fonts.lua                 <- text formatting snippets
│   ├── commands.lua              <- document structure snippets
│   └── text-Acronym.lua          <- text abbreviations
├── queries/latex/
│   ├── textobjects.scm           <- treesitter queries for navigation
│   └── highlights.scm            <- custom syntax highlights
├── spell/
│   ├── en.utf-8.add              <- mathematical spell dictionary
│   └── en.utf-8.add.spl          <- compiled dictionary
└── doc/
    └── noethervim-tex.txt        <- :help noethervim-tex
```

---

## Documentation

For the full reference, run inside Neovim:

```
:help noethervim-tex
```
