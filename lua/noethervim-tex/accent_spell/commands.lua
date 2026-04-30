-- noethervim-tex.accent_spell.commands
--
-- Registers the :NoetherTexAccent* user commands.  Called from
-- plugin/noethervim_tex.lua at plugin load.

local M = {}

---@param subcmd "enable" | "disable" | "toggle"
local function dispatch_toggle(subcmd)
  local accent = require("noethervim-tex.accent_spell")
  if subcmd == "enable" then
    accent.enable()
  elseif subcmd == "disable" then
    accent.disable()
  elseif subcmd == "toggle" or subcmd == nil or subcmd == "" then
    accent.toggle()
  else
    vim.notify(
      "[noethervim-tex] unknown subcommand: " .. tostring(subcmd)
        .. " (expected enable | disable | toggle)",
      vim.log.levels.ERROR
    )
  end
end

function M.register()
  vim.api.nvim_create_user_command("NoetherTexAccentSpell", function(opts)
    dispatch_toggle(opts.args)
  end, {
    nargs = "?",
    complete = function() return { "enable", "disable", "toggle" } end,
    desc = "noethervim-tex: enable/disable/toggle accent spell-check",
  })

  vim.api.nvim_create_user_command("NoetherTexAccentAdd", function(opts)
    require("noethervim-tex.accent_spell").add(opts.args ~= "" and opts.args or nil)
  end, {
    nargs = "?",
    desc = "noethervim-tex: add accented word to spellfile",
  })

  vim.api.nvim_create_user_command("NoetherTexAccentMarkWrong", function(opts)
    require("noethervim-tex.accent_spell").mark_wrong(opts.args ~= "" and opts.args or nil)
  end, {
    nargs = "?",
    desc = "noethervim-tex: mark accented word as misspelled",
  })

  vim.api.nvim_create_user_command("NoetherTexAccentSuggest", function()
    require("noethervim-tex.accent_spell").suggest()
  end, {
    desc = "noethervim-tex: replace accented token with a spell suggestion",
  })

  vim.api.nvim_create_user_command("NoetherTexAccentDiagnostic", function(opts)
    local accent = require("noethervim-tex.accent_spell")
    local arg = opts.args
    if arg == "on" then
      accent.set_diagnostic(true)
    elseif arg == "off" then
      accent.set_diagnostic(false)
    elseif arg == "toggle" or arg == nil or arg == "" then
      accent.set_diagnostic(nil)
    else
      vim.notify(
        "[noethervim-tex] unknown subcommand: " .. tostring(arg)
          .. " (expected on | off | toggle)",
        vim.log.levels.ERROR
      )
    end
  end, {
    nargs = "?",
    complete = function() return { "on", "off", "toggle" } end,
    desc = "noethervim-tex: toggle the INFO diagnostic (SpellBad highlight stays)",
  })
end

return M
