-- Native blink.cmp source completing figure filenames.
--
-- Fires only inside the braces of a figure-including macro, so it never
-- interferes with ordinary typing:
--
--   \incfig{cot|}            \includegraphics[width=7cm]{cot|}
--   \import{./figures/}{cot|}
--
-- It completes names, it does not insert environments: `FIG` and `<N>SFIG`
-- already template the figure block, and duplicating that here would mean
-- picking a LaTeX idiom on the user's behalf. This just answers "what was that
-- file called", which nothing else does.
--
-- The folder is resolved against the document, not the working directory, so
-- it keeps working when you open a paper from elsewhere:
--   require("noethervim-tex").setup({ figure_folders = { "figures", "images" } })
-- A string, an absolute path, or a function returning either is also accepted.

local CMDS = { "incfig", "includegraphics", "import", "subimport" }

local EXTENSIONS = {
	png = true, jpg = true, jpeg = true, pdf = true,
	eps = true, svg = true, tikz = true, pgf = true,
}

---Text already typed inside a figure macro's braces, or nil when the cursor is
---somewhere else entirely.
---@param before string  the line up to the cursor
---@return string|nil
local function figure_prefix(before)
	local prefix = before:match("{([^{}]*)$")
	if not prefix then
		return nil
	end
	local head = before:sub(1, #before - #prefix - 1)
	for _, cmd in ipairs(CMDS) do
		if head:match("\\" .. cmd .. "%s*$")            -- \incfig{
			or head:match("\\" .. cmd .. "%s*%b[]%s*$")   -- \includegraphics[...]{
			or head:match("\\" .. cmd .. "%s*%b{}%s*$")   -- \import{./figures/}{
		then
			return prefix
		end
	end
	return nil
end

---@return string|nil  first configured folder that exists, resolved absolutely
local function figure_dir()
	local ok, ntex = pcall(require, "noethervim-tex")
	local folders = ok and ntex.config and ntex.config.figure_folders
		or { "figures", "images" }
	if type(folders) == "function" then folders = folders() end
	if type(folders) == "string" then folders = { folders } end

	local base = vim.fn.expand("%:p:h")
	for _, folder in ipairs(folders) do
		local path = vim.fn.expand(folder)
		if not path:match("^[/~]") then
			path = base .. "/" .. path
		end
		path = vim.fs.normalize(path)
		if vim.fn.isdirectory(path) == 1 then
			return path
		end
	end
	return nil
end

---Distinct basenames of the image files in `dir`, extensions stripped, so a
---figure present as both .svg and .pdf is offered once.
---@param dir string
---@return string[]
local function figure_names(dir)
	local seen, names = {}, {}
	for entry, kind in vim.fs.dir(dir) do
		if kind == "file" then
			local stem, ext = entry:match("^(.*)%.([%w_]+)$")
			if stem and EXTENSIONS[ext:lower()] and not seen[stem] then
				seen[stem] = true
				table.insert(names, stem)
			end
		end
	end
	table.sort(names)
	return names
end

local Source = {}

function Source.new(_, _config)
	return setmetatable({}, { __index = Source })
end

function Source:get_trigger_characters()
	return { "{" }
end

function Source:get_completions(context, callback)
	local col    = context.cursor[2]
	local row0   = context.cursor[1] - 1
	local before = string.sub(context.line, 1, col)

	local prefix = figure_prefix(before)
	local dir    = prefix and figure_dir()
	if not dir then
		callback({ is_incomplete_forward = true, is_incomplete_backward = true, items = {} })
		return
	end

	local short = vim.fn.fnamemodify(dir, ":t")
	local items = {}
	for _, name in ipairs(figure_names(dir)) do
		table.insert(items, {
			label        = name,
			filterText   = name,
			kind         = require("blink.cmp.types").CompletionItemKind.File,
			labelDetails = { detail = " " .. short },
			textEdit     = {
				newText = name,
				range   = {
					start   = { line = row0, character = col - #prefix },
					["end"] = { line = row0, character = col },
				},
			},
		})
	end

	callback({ is_incomplete_forward = true, is_incomplete_backward = true, items = items })
end

return Source
