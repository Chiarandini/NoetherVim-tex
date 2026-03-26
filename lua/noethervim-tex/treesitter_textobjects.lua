--- LaTeX-specific treesitter-textobjects move keybindings.
--- Called from noethervim-tex.setup().
---
--- Uses the nvim-treesitter-textobjects move module directly (via buffer-local
--- keymaps on FileType) instead of configs.setup(), which has timing issues
--- when the plugin loads after treesitter has already attached to a buffer.
---
--- Keybindings (tex/latex buffers only):
---   ]g / [g  — next/prev theorem env (defn, thm, prop, lem, cor)
---   ]p / [p  — next/prev \begin{Proof}
---   ]P / [P  — next/prev \end{Proof}
---   ]x / [x  — next/prev \begin{example}
---   ]X / [X  — next/prev \end{example}
---   ]c / [c  — next/prev chapter

local M = {}

local function attach_keymaps(bufnr)
  local ok, move = pcall(require, "nvim-treesitter.textobjects.move")
  if not ok then return end

  local function map(lhs, fn, desc)
    vim.keymap.set("n", lhs, fn, { buffer = bufnr, silent = true, desc = desc })
  end

  map("]g", function() move.goto_next_start("@box_env",     "textobjects") end, "next theorem env")
  map("[g", function() move.goto_previous_start("@box_env", "textobjects") end, "prev theorem env")

  map("]p", function() move.goto_next_start("@proof_env",     "textobjects") end, "next \\begin{Proof}")
  map("[p", function() move.goto_previous_start("@proof_env", "textobjects") end, "prev \\begin{Proof}")

  map("]P", function() move.goto_next_start("@proof_end",     "textobjects") end, "next \\end{Proof}")
  map("[P", function() move.goto_previous_start("@proof_end", "textobjects") end, "prev \\end{Proof}")

  map("]x", function() move.goto_next_start("@example_env",     "textobjects") end, "next \\begin{example}")
  map("[x", function() move.goto_previous_start("@example_env", "textobjects") end, "prev \\begin{example}")

  map("]X", function() move.goto_next_start("@example_end",     "textobjects") end, "next \\end{example}")
  map("[X", function() move.goto_previous_start("@example_end", "textobjects") end, "prev \\end{example}")

  map("]c", function() move.goto_next_start("@chapter",     "textobjects") end, "next chapter")
  map("[c", function() move.goto_previous_start("@chapter", "textobjects") end, "prev chapter")
end

function M.setup()
  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("noethervim_tex_textobjects", { clear = true }),
    pattern = { "tex", "latex" },
    callback = function(ev)
      attach_keymaps(ev.buf)
    end,
  })

  -- Apply to any tex buffers already open (e.g. if setup() is called late).
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    local ft = vim.bo[bufnr].filetype
    if ft == "tex" or ft == "latex" then
      attach_keymaps(bufnr)
    end
  end
end

return M
