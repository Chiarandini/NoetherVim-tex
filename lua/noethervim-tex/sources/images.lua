-- Native blink.cmp source for inserting LaTeX figure environments.
-- Triggered when the entire line before the cursor is exactly ".".
-- Lists files from ./images/ and inserts a \begin{figure}...\end{figure} block.

local Source = {}

local function get_files_in_directory(directory)
	local files = {}
	local ok, pfile = pcall(io.popen, 'ls -p "' .. directory .. '" | grep -v /')
	if not ok or pfile == nil then return {} end
	for file in pfile:lines() do
		table.insert(files, file)
	end
	pfile:close()
	return files
end

local function latex_figure(image_name)
	return [[
\begin{figure}[H]
  \centering
  \includegraphics[width=7cm]{images/]] .. image_name .. [[}
  % \caption{}
  \label{fig:]] .. image_name .. [[}
\end{figure}
]]
end

function Source.new(_, _config)
	return setmetatable({}, { __index = Source })
end

function Source:get_trigger_characters()
	return { "." }
end

function Source:get_completions(context, callback)
	local col  = context.cursor[2]
	local row0 = context.cursor[1] - 1

	-- Only activate when the entire line before the cursor is exactly "."
	local before = string.sub(context.line, 1, col)
	if before ~= "." then
		callback({ is_incomplete_forward = false, is_incomplete_backward = false, items = {} })
		return
	end

	local images = get_files_in_directory("./images")
	local items  = {}
	for _, image in ipairs(images) do
		local stem = image:gsub("%.png$", "")
		table.insert(items, {
			label      = image,
			filterText = image,
			kind       = require("blink.cmp.types").CompletionItemKind.File,
			textEdit   = {
				newText = latex_figure(stem),
				range   = {
					start   = { line = row0, character = 0 },
					["end"] = { line = row0, character = col },
				},
			},
		})
	end

	callback({ is_incomplete_forward = false, is_incomplete_backward = false, items = items })
end

return Source
