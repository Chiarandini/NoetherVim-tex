---@diagnostic disable: undefined-global, unused-local
-- ========================================================================
--   ______   ___ __ __       _________  ____ ____  ____   ___ ______  _____
-- |      | /  _|  |  |     / ___|    \|    |    \|    \ /  _|      |/ ___/
-- |      |/  [_|  |  |    (   \_|  _  ||  ||  o  |  o  /  [_|      (   \_
-- |_|  |_|    _|_   _|     \__  |  |  ||  ||   _/|   _|    _|_|  |_|\__  |
--   |  | |   [_|     |     /  \ |  |  ||  ||  |  |  | |   [_  |  |  /  \ |
--   |  | |     |  |  |     \    |  |  ||  ||  |  |  | |     | |  |  \    |
--   |__| |_____|__|__|      \___|__|__|____|__|  |__| |_____| |__|   \___|
-- ========================================================================
-- Abbreviations used in this article and the LuaSnip docs
local ls = require("luasnip")
local s = ls.snippet
local sn = ls.snippet_node
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local c = ls.choice_node
local d = ls.dynamic_node
local fmt = require("luasnip.extras.fmt").fmt
local fmta = require("luasnip.extras.fmt").fmta
local rep = require("luasnip.extras").rep
local line_begin = require("luasnip.extras.expand_conditions").line_begin
local helper = require('noethervim-tex.luasnip_helper')
local get_visual = helper.get_visual_node
local get_visual_insert = helper.get_visual_insert_node
local tex_utils = helper.tex_utils

-- may still be useful in the future: /Users/nathanaelchwojko-srawkey/Library/Group Containers/UBF8T346G9.SyncClientSuite/.noindex//Documents

-- ┌──────────────────────┐
-- │ Custom Function Here │
-- └──────────────────────┘


local function getLabel(args, parent, old_state, prepend, old_text)
	if ((not prepend) or prepend == '') then
		return sn(nil, {t('\\label{'), i(1), t('}')})
	end
	return sn(nil, {t('\\label{' .. prepend), i(1), t('}')})
end

return
--  ┌                                                          ┐
--  │                     manual triggers                      │
--  └                                                          ┘
{
	-- hyperlink
	s(
		{ trig = "href", dscr = "The hyperref package's href{}{} command (for url links)" },
		fmta([[\href{<>}{<>}]], {
			i(1, "url"),
			i(2, "display name"),
		})
	),
		-- Auto-brace command: captures \cmd and expands to \cmd{<cursor>}
	-- place holder
	s(
		{trig = 'ph', wordtrig = 'true', name = 'place holder'},
		t('\\placeholder'),
		{
			show_condition = helper.at_line_start
		}
	),

},
--  ┌                                                          ┐
--  │                                                          │
--  │                      --autotriggers                      │
--  │                                                          │
--  └                                                          ┘
{
	-- part
	s(
		{ trig = "PART", dscr = "\\part" },
		fmta([[
		\part{<>}<>

		<>
		]], {
			d(1, get_visual_insert),
			c(2,
			{
				i(1),
				d(1, getLabel, {}, {user_args={'part:'}}),
				-- sn(nil, {d(1, getLabel, {1}, {'cha:'})}),
			}),
			i(0),
		})	),
	-- chapter
	s(
		{ trig = "CHA", dscr = "\\chapter" },
		fmta([[
		\chapter{<>}<>

		<>
		]], {
			d(1, get_visual_insert),
			c(2,
			{
				i(1),
				d(1, getLabel, {}, {user_args={'cha:'}}),
				-- sn(nil, {d(1, getLabel, {1}, {'cha:'})}),
			}),
			i(0),
		})	),
	-- section
	s(
		{ trig = "SSE", dscr = "\\section" },
		fmta([[
		\section{<>}<>

		<>
		]], {
			d(1, get_visual_insert),
			c(2,
			{
				i(1),
				d(1, getLabel, {}, {user_args={'sec:'}}),
				-- sn(nil, {d(1, getLabel, {1}, {'cha:'})}),
			}),
			i(0),
		})	),
	-- subsection
	s(
		{ trig = "SSS", dscr = "\\subsection" },
		fmta([[
		\subsection{<>}<>

		<>
		]], {
			d(1, get_visual_insert),
			c(2,
			{
				i(1),
				d(1, getLabel, {}, {user_args={'sec:'}}),
				-- sn(nil, {d(1, getLabel, {1}, {'cha:'})}),
			}),
			i(0),
		})	),
	-- subsubsection
	s(
		{ trig = "SS2", dscr = "\\subsubsection" },
		fmta([[
		\subsubsection{<>}<>

		<>
		]], {
			d(1, get_visual_insert),
			c(2,
			{
				i(1),
				d(1, getLabel, {}, {user_args={'sec:'}}),
				-- sn(nil, {d(1, getLabel, {1}, {'cha:'})}),
			}),
			i(0),
		})	),
	-- hidden subsection
	s(
		{ trig = "SS*", dscr = "\\subsection*" },
		fmta([[
		\subsection*{<>}

		<>
		]], {
			d(1, get_visual_insert),
			i(0),
		})	),
	-- red text
	s(
		{ trig = "RED", dscr = "xcolor red" },
		fmta([[ \textcolor{red}{<>}<> ]], {
			d(1, get_visual_insert), i(0)
		})),
	s(
		{ trig = "GREEN", dscr = "xcolor green" },
		fmta([[ \textcolor{green}{<>}<> ]], {
			d(1, get_visual_insert), i(0)
		})),
 --    s(
	-- 	{trig = "cp", name='citation', dscr='choose citation with Telescope Bibtex'},
	-- 	{c(1, {sn(nil, {t"\\citep{"}), sn(nil, {t"\\cite{"})}), i(2), t("}")},
	-- 	{
	-- 		callbacks = { [2] = { [events.enter] = function(_) return vim.cmd [[Telescope bibtex]] end } },
	-- 	}
	-- ),
}
