--- LaTeX treesitter textobject navigation.
--- Uses vim.treesitter directly — no dependency on nvim-treesitter-textobjects
--- or on nvim-treesitter highlight being active for tex buffers.
---
--- Keybindings (tex/latex buffers only):
---   ]g / [g  — next/prev theorem env (defn, thm, prop, lem, cor)
---   ]p / [p  — next/prev \begin{Proof}
---   ]P / [P  — next/prev \end{Proof}
---   ]x / [x  — next/prev \begin{example}
---   ]X / [X  — next/prev \end{example}
---   ]c / [c  — next/prev chapter

local M = {}

--- Jump to the nearest node matching `capture_name` in the latex textobjects
--- query. `forward = true` goes to the next occurrence, false to the previous.
local function navigate(capture_name, forward)
  local bufnr = vim.api.nvim_get_current_buf()

  local ok, parser = pcall(vim.treesitter.get_parser, bufnr, "latex")
  if not ok or not parser then
    vim.notify("noethervim-tex: no latex treesitter parser available", vim.log.levels.WARN)
    return
  end

  local trees = parser:parse()
  if not trees or not trees[1] then return end

  local query = vim.treesitter.query.get("latex", "textobjects")
  if not query then
    vim.notify("noethervim-tex: latex textobjects query not found", vim.log.levels.WARN)
    return
  end

  local cursor  = vim.api.nvim_win_get_cursor(0)
  local cur_row = cursor[1] - 1  -- convert to 0-indexed
  local cur_col = cursor[2]

  local best_row, best_col

  for id, node in query:iter_captures(trees[1]:root(), bufnr) do
    if query.captures[id] == capture_name then
      local sr, sc = node:start()
      if forward then
        -- want the closest node strictly after cursor
        if sr > cur_row or (sr == cur_row and sc > cur_col) then
          if not best_row or sr < best_row or (sr == best_row and sc < best_col) then
            best_row, best_col = sr, sc
          end
        end
      else
        -- want the closest node strictly before cursor
        if sr < cur_row or (sr == cur_row and sc < cur_col) then
          if not best_row or sr > best_row or (sr == best_row and sc > best_col) then
            best_row, best_col = sr, sc
          end
        end
      end
    end
  end

  if best_row then
    vim.cmd("normal! m'")  -- add current position to jumplist
    vim.api.nvim_win_set_cursor(0, { best_row + 1, best_col })
  end
end

local function attach_keymaps(bufnr)
  local function map(lhs, capture, forward, desc)
    vim.keymap.set("n", lhs, function() navigate(capture, forward) end,
      { buffer = bufnr, silent = true, desc = desc })
  end

  map("]g", "box_env",     true,  "next theorem env")
  map("[g", "box_env",     false, "prev theorem env")
  map("]p", "proof_env",   true,  "next \\begin{Proof}")
  map("[p", "proof_env",   false, "prev \\begin{Proof}")
  map("]P", "proof_end",   true,  "next \\end{Proof}")
  map("[P", "proof_end",   false, "prev \\end{Proof}")
  map("]x", "example_env", true,  "next \\begin{example}")
  map("[x", "example_env", false, "prev \\begin{example}")
  map("]X", "example_end", true,  "next \\end{example}")
  map("[X", "example_end", false, "prev \\end{example}")
  map("]c", "chapter",     true,  "next chapter")
  map("[c", "chapter",     false, "prev chapter")
end

function M.setup()
  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("noethervim_tex_textobjects", { clear = true }),
    pattern = { "tex", "latex" },
    callback = function(ev) attach_keymaps(ev.buf) end,
  })

  -- Apply to any tex buffers already open when setup() is called.
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    local ft = vim.bo[bufnr].filetype
    if ft == "tex" or ft == "latex" then
      attach_keymaps(bufnr)
    end
  end
end

return M
