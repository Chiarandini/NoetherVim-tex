--- LaTeX-specific treesitter-textobjects move keybindings.
--- Called from noethervim-tex.setup(); extends the nvim-treesitter config
--- with goto keymaps that target LaTeX environment captures defined in
--- queries/latex/textobjects.scm.
---
--- Keybindings added:
---   ]g / [g  — next/prev theorem env (defn, thm, prop, lem, cor)
---   ]p / [p  — next/prev \begin{Proof}
---   ]P / [P  — next/prev \end{Proof}
---   ]x / [x  — next/prev \begin{example}
---   ]X / [X  — next/prev \end{example}
---   ]c / [c  — next/prev chapter

local M = {}

function M.setup()
  local ok, configs = pcall(require, "nvim-treesitter.configs")
  if not ok then return end

  ---@diagnostic disable-next-line: missing-fields
  configs.setup({
    textobjects = {
      move = {
        goto_next_start = {
          ["]g"] = { query = "@box_env",     desc = "next theorem env" },
          ["]p"] = { query = "@proof_env",   desc = "next \\begin{Proof}" },
          ["]P"] = { query = "@proof_end",   desc = "next \\end{Proof}" },
          ["]x"] = { query = "@example_env", desc = "next \\begin{example}" },
          ["]X"] = { query = "@example_end", desc = "next \\end{example}" },
          ["]c"] = { query = "@chapter",     desc = "next chapter" },
        },
        goto_previous_start = {
          ["[g"] = { query = "@box_env",     desc = "prev theorem env" },
          ["[p"] = { query = "@proof_env",   desc = "prev \\begin{Proof}" },
          ["[P"] = { query = "@proof_end",   desc = "prev \\end{Proof}" },
          ["[x"] = { query = "@example_env", desc = "prev \\begin{example}" },
          ["[X"] = { query = "@example_end", desc = "prev \\end{example}" },
          ["[c"] = { query = "@chapter",     desc = "prev chapter" },
        },
      },
    },
  })
end

return M
