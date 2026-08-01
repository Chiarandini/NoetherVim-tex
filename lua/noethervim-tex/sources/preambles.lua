-- Native blink.cmp source for inserting LaTeX preamble fragments.
-- Triggered by "@" at the very start of a line while outside \begin{document}.
-- Lists the .tex files in the configured preamble folder and inserts the
-- contents of the chosen one, with the file shown in the documentation window
-- so you can see what you are about to paste.
--
-- The preamble folder is configurable via:
--   require("noethervim-tex").setup({ preamble_folder = "~/my/preambles/" })
-- Defaults to stdpath("config")/preamble/.

local function get_preamble_folder()
	local ok, ntex = pcall(require, "noethervim-tex")
	local folder = (ok and ntex.config and ntex.config.preamble_folder)
		or (vim.fn.stdpath("config") .. "/preamble/")
	return vim.fn.expand(folder)
end

---@return { name: string, path: string }[]
local function get_fragments(directory)
	local fragments = {}
	if vim.fn.isdirectory(directory) == 0 then
		return fragments
	end
	for entry, kind in vim.fs.dir(directory) do
		if kind == "file" and entry:match("%.tex$") then
			table.insert(fragments, {
				name = (entry:gsub("%.tex$", "")),
				path = directory .. "/" .. entry,
			})
		end
	end
	table.sort(fragments, function(a, b) return a.name < b.name end)
	return fragments
end

local function in_preamble()
	local ok, is_inside = pcall(vim.fn["vimtex#env#is_inside"], "document")
	if not ok then
		return true
	end
	return not (is_inside[1] > 0 and is_inside[2] > 0)
end

local Source = {}

function Source.new(_, _config)
	return setmetatable({}, { __index = Source })
end

function Source:get_trigger_characters()
	return { "@" }
end

function Source:get_completions(context, callback)
	local col  = context.cursor[2]
	local row0 = context.cursor[1] - 1

	-- Only activate when the line before the cursor is exactly "@" plus optional
	-- name characters, and the cursor is outside the document environment.
	local before = string.sub(context.line, 1, col)
	if not before:match("^@[%w%-_]*$") or not in_preamble() then
		callback({ is_incomplete_forward = true, is_incomplete_backward = true, items = {} })
		return
	end

	-- Rescanned per request so a fragment added mid-session shows up without
	-- restarting Neovim.
	local items = {}
	for _, fragment in ipairs(get_fragments(get_preamble_folder())) do
		local ok, lines = pcall(vim.fn.readfile, fragment.path)
		if ok then
			local body = table.concat(lines, "\n")
			table.insert(items, {
				label         = fragment.name,
				filterText    = fragment.name,
				kind          = require("blink.cmp.types").CompletionItemKind.Snippet,
				labelDetails  = { detail = " preamble" },
				documentation = {
					kind  = "markdown",
					value = "```tex\n" .. body .. "\n```",
				},
				textEdit      = {
					newText = body,
					range   = {
						start   = { line = row0, character = 0 },
						["end"] = { line = row0, character = col },
					},
				},
			})
		end
	end

	callback({ is_incomplete_forward = true, is_incomplete_backward = true, items = items })
end

return Source
