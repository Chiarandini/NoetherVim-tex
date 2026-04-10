-- Native blink.cmp source for inserting LaTeX preamble snippets.
-- Triggered when typing "@" at the very start of a line while outside \begin{document}.
-- Lists .tex files from the configured preamble folder and inserts the filename (without .tex).
--
-- The preamble folder is configurable via:
--   require("noethervim-tex").setup({ preamble_folder = "~/my/preambles/" })
-- Defaults to stdpath("config")/preamble/.

local function get_preamble_folder()
	local ok, ntex = pcall(require, "noethervim-tex")
	if ok and ntex.config and ntex.config.preamble_folder then
		return ntex.config.preamble_folder
	end
	return vim.fn.stdpath("config") .. "/preamble/"
end

local function get_preamble_names(directory)
	local names = {}
	local ok, pfile = pcall(io.popen, 'ls -p "' .. directory .. '" | grep -v /')
	if not ok or pfile == nil then return {} end
	for file in pfile:lines() do
		if file:match("%.tex$") then
			table.insert(names, (file:gsub("%.tex$", "")))
		end
	end
	pfile:close()
	return names
end

local function in_preamble()
	local is_inside = vim.fn["vimtex#env#is_inside"]("document")
	return not (is_inside[1] > 0 and is_inside[2] > 0)
end

local Source = {}

function Source.new(_, _config)
	local self = setmetatable({}, { __index = Source })
	self.words = get_preamble_names(get_preamble_folder())
	return self
end

function Source:get_trigger_characters()
	return { "@" }
end

function Source:get_completions(context, callback)
	local col  = context.cursor[2]
	local row0 = context.cursor[1] - 1

	-- Only activate when line before cursor is exactly "@" + optional alpha chars,
	-- and cursor is outside the document environment.
	local before = string.sub(context.line, 1, col)
	if not before:match("^@%a*$") or not in_preamble() then
		callback({ is_incomplete_forward = true, is_incomplete_backward = true, items = {} })
		return
	end

	local items = {}
	for _, word in pairs(self.words) do
		table.insert(items, {
			label        = word,
			filterText   = word,
			kind         = require("blink.cmp.types").CompletionItemKind.Snippet,
			labelDetails = { detail = "preamble" },
			textEdit     = {
				newText = word,
				range   = {
					start   = { line = row0, character = 0 },
					["end"] = { line = row0, character = col },
				},
			},
		})
	end

	callback({ is_incomplete_forward = true, is_incomplete_backward = true, items = items })
end

return Source
