-- noethervim-tex health check.
--
-- Run with  :checkhealth noethervim-tex .

local M = {}

local function start(name)
  if vim.health and vim.health.start then return vim.health.start(name) end
  return vim.health.report_start(name)
end

local function ok(msg) return (vim.health.ok or vim.health.report_ok)(msg) end
local function warn(msg, advice)
  if vim.health.warn then return vim.health.warn(msg, advice) end
  return vim.health.report_warn(msg, advice)
end
local function err(msg, advice)
  if vim.health.error then return vim.health.error(msg, advice) end
  return vim.health.report_error(msg, advice)
end
local function info(msg)
  if vim.health.info then return vim.health.info(msg) end
  return vim.health.report_info(msg)
end

local function plugin_root()
  local sentinel = debug.getinfo(1, "S").source:sub(2)
  return vim.fn.fnamemodify(sentinel, ":h:h:h")
end

function M.check()
  start("noethervim-tex")

  -- ── Neovim version ───────────────────────────────────────────────
  if vim.fn.has("nvim-0.10") == 1 then
    ok("Neovim >= 0.10")
  else
    err("Neovim >= 0.10 required")
  end

  -- ── Required runtime deps ────────────────────────────────────────
  if pcall(require, "luasnip") then
    ok("LuaSnip is installed")
  else
    err("LuaSnip not found", { "Add 'L3MON4D3/LuaSnip' to your plugin manager." })
  end

  -- vimtex is checked indirectly: g:vimtex is set after it loads.
  if vim.fn.exists("g:vimtex") == 1 then
    ok("vimtex is loaded")
  else
    warn(
      "vimtex not detected",
      { "Snippet expansion in math zones depends on vimtex's syntax;",
        "install lervag/vimtex if you haven't already." }
    )
  end

  -- ── Treesitter latex parser ─────────────────────────────────────
  local ts_ok = pcall(vim.treesitter.language.add, "latex")
  if ts_ok then
    ok("latex treesitter parser available")
  else
    warn(
      "latex treesitter parser not installed",
      { "The accent spell-check feature falls back to no math/comment",
        "exclusion without it. Install with :TSInstall latex." }
    )
  end

  -- ── Shipped spell files ──────────────────────────────────────────
  local root = plugin_root()
  local spell_files = {
    { path = root .. "/spell/en.utf-8.add",           label = "math vocabulary" },
    { path = root .. "/spell/accents.utf-8.add", label = "accent-name dictionary" },
  }
  for _, entry in ipairs(spell_files) do
    if vim.uv.fs_stat(entry.path) then
      local spl = entry.path .. ".spl"
      local add_stat = vim.uv.fs_stat(entry.path)
      local spl_stat = vim.uv.fs_stat(spl)
      if not spl_stat then
        warn(("%s: .spl missing -- will be built on next plugin load"):format(entry.label))
      elseif add_stat and add_stat.mtime.sec > spl_stat.mtime.sec then
        warn(("%s: .spl is older than .add -- restart Neovim to rebuild"):format(entry.label))
      else
        ok(("%s spell file compiled and loaded"):format(entry.label))
      end
    else
      err(("%s spell file missing at %s"):format(entry.label, entry.path))
    end
  end

  -- ── Accent spell-check feature ───────────────────────────────────
  local accent = require("noethervim-tex.accent_spell")
  local cfg = accent.config()
  info(("accent spell-check: enabled=%s, severity=%s, debounce_ms=%d"):format(
    tostring(cfg.enabled),
    tostring(cfg.severity),
    cfg.debounce_ms
  ))

  -- ── Optional deps ────────────────────────────────────────────────
  if pcall(require, "blink.cmp") then
    ok("blink.cmp is installed (preamble completion source available)")
  else
    info("blink.cmp not installed -- preamble completion disabled (optional)")
  end
end

return M
