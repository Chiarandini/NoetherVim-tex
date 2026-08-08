--- Keep the PDF viewer on the line the cursor is on.
---
--- VimTeX already knows how to jump the viewer to the cursor: `:VimtexView`
--- performs a SyncTeX forward search. What it has no opinion about is when
--- to do it, so the viewer only moves when you ask. This drives it from
--- cursor movement instead, which turns the PDF into a second view of the
--- document rather than something you check on.
---
--- Off until asked for, per buffer. Forward search spawns a viewer IPC call,
--- and doing that on every cursor movement in every tex buffer for the whole
--- session is a cost most editing does not want to pay.
---
--- Requires a viewer VimTeX can drive (Skim, Zathura, Sioyek); with none
--- configured `:VimtexView` is a no-op and so is this.

local M = {}

local DEFAULTS = {
  --- `"moved"` syncs as the cursor moves, debounced; `"held"` waits for the
  --- cursor to stop. Held costs less and feels a beat behind, which matters
  --- on viewers that redraw slowly.
  event    = "moved",
  --- Quiet period before a sync, in ms. Only meaningful for `"moved"`.
  debounce = 150,
}

M.config = vim.deepcopy(DEFAULTS)

local group = vim.api.nvim_create_augroup("noethervim_tex_follow", { clear = true })
local timer = nil

--- Syncing on every CursorMoved would fire a viewer call per keystroke of
--- `j`. Coalesce into one call after the cursor has been still, and skip
--- when the line has not changed -- horizontal movement within a line maps
--- to the same SyncTeX position, so the viewer would not move anyway.
local function schedule(buf)
  local line = vim.api.nvim_win_get_cursor(0)[1]
  if vim.b[buf].noethervim_tex_follow_line == line then return end
  vim.b[buf].noethervim_tex_follow_line = line

  if timer then
    timer:stop()
    timer:close()
    timer = nil
  end

  local function sync()
    -- The buffer may have been closed, or follow switched off, during the
    -- wait. `silent!` keeps a viewer that has since exited from raising.
    if vim.api.nvim_buf_is_valid(buf) and vim.b[buf].noethervim_tex_follow then
      vim.cmd("silent! VimtexView")
    end
  end

  if M.config.debounce <= 0 then
    return sync()
  end
  timer = vim.uv.new_timer()
  timer:start(M.config.debounce, 0, vim.schedule_wrap(function()
    if timer then
      timer:stop()
      timer:close()
      timer = nil
    end
    sync()
  end))
end

--- Turn follow on or off for `buf`, defaulting to the current buffer.
---@param buf? integer
---@param on? boolean  nil toggles
---@return boolean enabled
function M.toggle(buf, on)
  buf = (buf == nil or buf == 0) and vim.api.nvim_get_current_buf() or buf
  if on == nil then on = not vim.b[buf].noethervim_tex_follow end
  vim.b[buf].noethervim_tex_follow = on or nil
  vim.b[buf].noethervim_tex_follow_line = nil

  if on then
    -- Land the viewer on the current line straight away. Waiting for the
    -- next cursor movement would make turning it on look like it failed.
    vim.cmd("silent! VimtexView")
  end
  return on
end

function M.enabled(buf)
  buf = (buf == nil or buf == 0) and vim.api.nvim_get_current_buf() or buf
  return vim.b[buf].noethervim_tex_follow == true
end

function M.setup(opts)
  M.config = vim.tbl_extend("force", vim.deepcopy(DEFAULTS), opts or {})

  vim.api.nvim_clear_autocmds({ group = group })
  vim.api.nvim_create_autocmd(
    M.config.event == "held" and "CursorHold" or "CursorMoved",
    {
      group = group,
      callback = function(ev)
        if not vim.b[ev.buf].noethervim_tex_follow then return end
        schedule(ev.buf)
      end,
    })

  vim.api.nvim_create_user_command("VimtexFollowToggle", function()
    local on = M.toggle(0)
    vim.notify(
      "PDF follows the cursor: " .. (on and "on" or "off"),
      vim.log.levels.INFO, { title = "noethervim-tex" })
  end, { desc = "toggle the PDF following the cursor" })
end

return M
