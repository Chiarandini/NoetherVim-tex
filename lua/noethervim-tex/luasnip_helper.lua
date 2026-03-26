--
--@diagnostic disable: unused-local
local ls = require("luasnip")
local s = ls.snippet
local sn = ls.snippet_node
local isn = ls.indent_snippet_node
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local c = ls.choice_node
local d = ls.dynamic_node
local r = ls.restore_node
local events = require("luasnip.util.events")
local ai = require("luasnip.nodes.absolute_indexer")
local extras = require("luasnip.extras")
local l = extras.lambda
local rep = extras.rep
local p = extras.partial
local m = extras.match
local n = extras.nonempty
local dl = extras.dynamic_lambda
local fmt = require("luasnip.extras.fmt").fmt
local fmta = require("luasnip.extras.fmt").fmta
local conds = require("luasnip.extras.expand_conditions")
local postfix = require("luasnip.extras.postfix").postfix
local types = require("luasnip.util.types")
local parse = require("luasnip.util.parser").parse_snippet
local line_begin = require("luasnip.extras.expand_conditions").line_begin

local M = {}

-- ----------------------------------------------------------------------------
-- Summary: When `LS_SELECT_RAW` is populated with a visual selection, the function
-- returns an insert node whose initial text is set to the visual selection.
-- When `LS_SELECT_RAW` is empty, the function simply returns an empty insert node.

local function modifyInitialWhiteSpace(text)
	return ' ' .. text:gsub("^%s*(.+)", "%1")
end

function M.get_visual_node(args, parent)
	if #parent.snippet.env.LS_SELECT_RAW > 0 then
		return sn(nil, t(parent.snippet.env.LS_SELECT_RAW))
	else -- If LS_SELECT_RAW is empty, return a blank insert node
		return sn(nil, i(1))
	end
end


function M.get_visual_insert_node(args, parent)
	if #parent.snippet.env.LS_SELECT_RAW > 0 then
		return sn(nil, i(1, parent.snippet.env.LS_SELECT_RAW))
	else -- If LS_SELECT_RAW is empty, return a blank insert node
		return sn(nil, i(1))
	end
end

function M.get_visual_space_insert_node(args, parent)
	if #parent.snippet.env.LS_SELECT_RAW > 0 then
		return sn(nil, i(1, modifyInitialWhiteSpace(parent.snippet.env.LS_SELECT_RAW)))
	else -- If LS_SELECT_RAW is empty, return a blank insert node
		return sn(nil, i(1))
	end
end

function M.get_visual_text(args, parent)
	return parent.snippet.env.LS_SELECT_RAW
end

---Returns whether the cursor is at the start of a line with a ":" (for my personal tcolor
--environments)
---@return boolean
function M.at_line_start_tcolor(_, _)
	local in_doc = vim.fn["vimtex#env#is_inside"]('document')
	return (vim.api
	.nvim_get_current_line()
	:sub(1, vim.api.nvim_win_get_cursor(0)[2])
	:gsub(':%w*', '')
	:match('^$') ~= nil) and (in_doc[1] > 0 and in_doc[2] > 0)
end

function M.at_line_start(_, _)
	local in_doc = vim.fn["vimtex#env#is_inside"]('document')
	return (vim.api
	.nvim_get_current_line()
	:sub(1, vim.api.nvim_win_get_cursor(0)[2])
	:gsub('%w*', '')
	:match('^$') ~= nil) and (in_doc[1] > 0 and in_doc[2] > 0)
end

function M.line_start(_, _)
	return (vim.api
	.nvim_get_current_line()
	:sub(1, vim.api.nvim_win_get_cursor(0)[2])
	:gsub('%w*', '')
	:match('^$') ~= nil)
end


-- s(
-- 	"test_selected_text",
-- 	f(function(args, snip)
-- 		local res, env = {}, snip.env
-- 		table.insert(res, "Selected Text (current line is " .. env.TM_LINE_NUMBER .. "):")
-- 		for _, ele in ipairs(env.LS_SELECT_RAW) do
-- 			table.insert(res, ele)
-- 		end
-- 		return res
-- 	end, {})
-- ),

-- ┌────────────────────────────┐
-- │ for detecting environments │
-- └────────────────────────────┘

local tex_utils = {}
tex_utils.in_env = function(name) -- generic environment detection (within document)
	local is_inside = vim.fn["vimtex#env#is_inside"](name)
	local in_doc = vim.fn["vimtex#env#is_inside"]('document')
	return (is_inside[1] > 0 and is_inside[2] > 0) and (in_doc[1] > 0 and in_doc[2] > 0)
end

tex_utils.in_mathzone = function() -- math context detection
	return ( vim.fn["vimtex#syntax#in_mathzone"]() == 1 )
end

--- Check if in preamble
---@return boolean
tex_utils.in_document = function()
	local in_doc = vim.fn["vimtex#env#is_inside"]('document')
	return (in_doc[1] > 0 and in_doc[2] > 0)
end

tex_utils.in_text = function()
	local in_doc = vim.fn["vimtex#env#is_inside"]('document')
	return ( not tex_utils.in_mathzone() ) and (in_doc[1] > 0 and in_doc[2] > 0)
end

tex_utils.beginning_text = function()
	return (not tex_utils.in_mathzone()) and line_begin and tex_utils.in_document()
end

tex_utils.in_comment = function() -- comment detection
	return vim.fn["vimtex#syntax#in_comment"]() == 1
end

tex_utils.in_equation = function() -- equation environment detection
	return tex_utils.in_env("equation")
end

tex_utils.in_align = function() -- equation environment detection
	return tex_utils.in_env("align*") or tex_utils.in_env("align")
end

tex_utils.in_itemize = function() -- itemize environment detection
	return tex_utils.in_env("itemize")
end

tex_utils.in_cases = function() -- itemize environment detection
	return tex_utils.in_env("cases")
end

tex_utils.in_tikz = function() -- TikZ picture environment detection
	return tex_utils.in_env("tikzpicture")
end
--- beginning of line and in preamble (i.e., not in document environemnt)
---@return boolean
tex_utils.in_preamble = function()
	local beginning = vim.api
		.nvim_get_current_line()
		:sub(1, vim.api.nvim_win_get_cursor(0)[2])
		:gsub('%w*', '')
		:match('^$') ~= nil
	return beginning and (not tex_utils.in_document())
end

M.tex_utils = tex_utils


-- ┌──────────────────────────────────┐
-- │ For creating tables and matrices │
-- └──────────────────────────────────┘

function M.mat(args, snip, opts)
	local rows = tonumber(snip.captures[2])
	local cols = tonumber(snip.captures[3])
	local nodes = {}
	local ins_indx = 1
	for j = 1, rows do
		table.insert(nodes, r(ins_indx, tostring(j) .. "x1", i(1)))
		ins_indx = ins_indx + 1
		for k = 2, cols do
			table.insert(nodes, t(" & "))
			table.insert(nodes, r(ins_indx, tostring(j) .. "x" .. tostring(k), i(1)))
			ins_indx = ins_indx + 1
		end
		table.insert(nodes, t({ "\\\\", "" }))
	end
	return sn(nil, nodes)
end

function M.square_mat(args, snip, opts)
	local rows = tonumber(snip.captures[2])
	local cols = tonumber(snip.captures[2])
	local nodes = {}
	local ins_indx = 1
	for j = 1, rows do
		table.insert(nodes, r(ins_indx, tostring(j) .. "x1", i(1)))
		ins_indx = ins_indx + 1
		for k = 2, cols do
			table.insert(nodes, t(" & "))
			table.insert(nodes, r(ins_indx, tostring(j) .. "x" .. tostring(k), i(1)))
			ins_indx = ins_indx + 1
		end
		table.insert(nodes, t({ "\\\\", "" }))
	end
	return sn(nil, nodes)
end


function M.table_node(args, parent, opts)
	local tabs = {}
	local count
	table = args[1][1]:gsub("%s", ""):gsub("|", "")
	count = table:len()
	for j = 1, count do
		local iNode
		iNode = i(j)
		tabs[2 * j - 1] = iNode
		if j ~= count then
			tabs[2 * j] = t(" & ")
		end
	end
	return sn(nil, tabs)
end

Rec_table = function()
	return sn(nil, {
		c(1, {
			t({ "" }),
			sn(nil, { t({ "\\\\", "" }), d(1, M.table_node, { ai[1] }), d(2, Rec_table, { ai[1] }) }),
		}),
	})
end

M.rec_table = Rec_table

-- ┌────────────────┐
-- │ Make a ref Tag │
-- └────────────────┘

function M.titlecase(str)
	local result = ""
	for word in string.gmatch(str, "%S+") do
		local first = string.sub(word, 1, 1)
		result = (result .. string.upper(first) .. string.lower(string.sub(word, 2)) .. " ")
	end
	result = result:gsub(" Iii", " III")
	result = result:gsub(" Ii", " II")
	result = result:gsub(" Iv", " IV")
	result = result:gsub("Dvr", "DVR")
	result = result:gsub(" Of ", " of ")
	result = result:gsub(" And ", " and ")
	result = result:gsub(" Only ", " only ")
	result = result:gsub(" Then ", " then ")
	result = result:gsub(" Using ", " using ")
	result = result:gsub(" In ", " in ")
	result = result:gsub(" Is ", " is ")
	return result
end

function M.makeRefTag(envTitle)
	-- This method definitely has flaws, namely there are overlaps that could happen when certain combinations occur, but it works 98% of the time and that is good enough for my purposes
	local indexName = M.titlecase(envTitle)
	indexName = indexName:gsub("'S", "'s")
	indexName = indexName:gsub(",", "")
	indexName = indexName:gsub("Transformation", "Trans")
	indexName = indexName:gsub("Totally", "Tot")
	indexName = indexName:gsub("Cohomology", "Cohom")
	indexName = indexName:gsub("Homology", "Homol")
	indexName = indexName:gsub("Total", "Tot")
	indexName = indexName:gsub("Absolutely", "Abs")
	indexName = indexName:gsub("Absolute", "Abs")
	indexName = indexName:gsub("Continuous", "Cont")
	indexName = indexName:gsub("Distribution", "Distrib")
	indexName = indexName:gsub("Continuity", "Cont")
	indexName = indexName:gsub("Differentiable", "Diffble")
	indexName = indexName:gsub("Linear", "Lin")
	indexName = indexName:gsub("Decomposition", "Decomp")
	indexName = indexName:gsub("Singular", "Sing")
	indexName = indexName:gsub("Measureable", "Measble")
	indexName = indexName:gsub("Measurable", "Measble")
	indexName = indexName:gsub("Measure", "Meas")
	indexName = indexName:gsub("Integrable", "Intble")
	indexName = indexName:gsub("Integral", "Int")
	indexName = indexName:gsub("Diffeomorphism", "Diffeo")
	indexName = indexName:gsub("Equivalent", "Equiv")
	indexName = indexName:gsub("Condition", "Cond")
	indexName = indexName:gsub("Category", "Cat")
	indexName = indexName:gsub("Categories", "Cat")
	indexName = indexName:gsub("Categories", "Cat")
	indexName = indexName:gsub("Functions", "Func")
	indexName = indexName:gsub("Function", "Func")
	indexName = indexName:gsub("Functors", "Funct")
	indexName = indexName:gsub("Functor", "Funct")
	indexName = indexName:gsub("Degree", "Deg")
	indexName = indexName:gsub("Extension", "Ext")
	indexName = indexName:gsub("Equivalence", "Equiv")
	indexName = indexName:gsub("Separable", "Sep")
	indexName = indexName:gsub("Connected", "Conn")
	indexName = indexName:gsub("Polynomial", "Poly")
	indexName = indexName:gsub("Characteristic", "Char")
	indexName = indexName:gsub("isomorphism", "Iso")
	indexName = indexName:gsub("Isomorphism", "Iso")
	indexName = indexName:gsub("Homomorphism", "Homo")
	indexName = indexName:gsub("Compact", "Comp")
	indexName = indexName:gsub("Universal Property", "UniProp")
	indexName = indexName:gsub("'S", "")
	indexName = indexName:gsub("'s", "")
	indexName = indexName:gsub("If And Only IF", "Iff")
	indexName = indexName:gsub("Projective", "Proj")
	indexName = indexName:gsub("Spectrum", "Spec")
	indexName = indexName:gsub("Spectra", "Spec")
	indexName = indexName:gsub("Spaces", "Sp")
	indexName = indexName:gsub("Space", "Sp")
	indexName = indexName:gsub("Group", "Grp")
	indexName = indexName:gsub("Module", "Mod")
	indexName = indexName:gsub("Vector", "Vec")
	indexName = indexName:gsub("Noetherian", "Noeth")
	indexName = indexName:gsub("Correspondence", "Corresp")
	indexName = indexName:gsub("Corresponding", "Corresp")
	indexName = indexName:gsub("Galois", "Gal")
	indexName = indexName:gsub("Maximal", "Max")
	indexName = indexName:gsub("Maximally", "Maxly")
	indexName = indexName:gsub("Theorem", "Thm")
	indexName = indexName:gsub("Fundamental", "Fund")
	indexName = indexName:gsub("Of", "")
	indexName = indexName:gsub("Properties", "Prop")
	indexName = indexName:gsub("Product", "Prod")
	indexName = indexName:gsub("Product", "Prod")
	indexName = indexName:gsub("Image", "Im")
	indexName = indexName:gsub("Representation", "Rep")
	indexName = indexName:gsub("$Rw$", "Then")
	indexName = indexName:gsub("W.R.T.", "")
	indexName = indexName:gsub("When", "")
	indexName = indexName:gsub(" A ", " ")
	indexName = indexName:gsub("The", "")
	indexName = indexName:gsub("$", "")
	indexName = indexName:gsub("\\", "")
	indexName = indexName:gsub("Ii", "II")
	indexName = indexName:gsub("Iii", "III")
	indexName = indexName:gsub("dVR", "DVR")

	if #indexName > 1 then
		indexName = indexName:gsub("^%u", string.lower)
	-- all reference tags start with lowerase, with these exceptions
	indexName = indexName:gsub("dVR", "DVR")
	indexName = indexName:gsub("pID", "PID")
	indexName = indexName:gsub("uFD", "UFD")
	end
	return indexName:gsub(" ", "")
end

--  ╔══════════════════════════════════════════════════════════╗
--  ║        For detecting latex in non-latex document         ║
--  ╚══════════════════════════════════════════════════════════╝

-- NOTE: apparently this is getting depricated
-- local ts_utils = require("nvim-treesitter.ts_utils")

local MATH_NODES = {
  displayed_equation = true,
  inline_formula = true,
  math_environment = true,
}

function M.in_latex()
	local node = vim.treesitter.get_node()

	while node do
		if node:type() == "text_mode" then
			return false
		elseif MATH_NODES[node:type()] then
			return true
		end
		node = node:parent()
	end
	return false
end

--  ╔══════════════════════════════════════════════════════════╗
--  ║                 For creating subfigures                  ║
--  ╚══════════════════════════════════════════════════════════╝

local function subFigureNode(width)
	return {t({'\\begin{subfigure}{' .. tostring(width) .. '\\textwidth}', '\\centering', '\\includegraphics[width='}), i(1, '5'), t('cm]{'), i(2), t({'}', '\\caption{'}), i(3), t({'}', '\\label{'}), i(4, 'fig:'), t({'}', '\\end{subfigure}', ''})}
end

function M.subfigures(args, snip, opts)
	local count = tonumber(snip.captures[1])
	local nodes = {}
	for j= 1,count do
		table.insert(nodes, subFigureNode(0.333))
	end
	return sn(nil, nodes)
end

return M
