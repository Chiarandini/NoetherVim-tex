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
-- Preamble templates. Every snippet here is gated on tex_utils.in_preamble,
-- so the triggers stay out of the way once \begin{document} is open.
--
-- These are deliberately self-contained: no file IO and no reliance on
-- preamble_folder, so they work on a fresh install. To assemble a preamble out
-- of your own modular fragments instead, type `@` at the start of a line and
-- use the preamble completion source.
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

local in_preamble = {
	condition = tex_utils.in_preamble,
	show_condition = tex_utils.in_preamble,
}

return
{
--  ╔══════════════════════════════════════════════════════════╗
--  ║                    document skeletons                    ║
--  ╚══════════════════════════════════════════════════════════╝

	s( -- AMS article, the usual starting point for a paper
		{ trig = 'amsart', dscr = 'amsart skeleton with amsthm environments' },
		fmta([[
		\documentclass[11pt]{amsart}
		\usepackage{amsmath, amssymb, amsthm, mathtools}
		\usepackage[hidelinks]{hyperref}
		\usepackage{cleveref}

		\newtheorem{theorem}{Theorem}[section]
		\newtheorem{lemma}[theorem]{Lemma}
		\newtheorem{proposition}[theorem]{Proposition}
		\newtheorem{corollary}[theorem]{Corollary}
		\theoremstyle{definition}
		\newtheorem{definition}[theorem]{Definition}
		\newtheorem{example}[theorem]{Example}
		\theoremstyle{remark}
		\newtheorem{remark}[theorem]{Remark}

		\title{<>}
		\author{<>}

		\begin{document}
		\maketitle

		<>

		\end{document}
		]], {
			i(1, 'Title'),
			i(2, 'Author'),
			i(0),
		}),
		in_preamble
	),
	s( -- standalone, for a figure compiled on its own
		{ trig = 'standalone', dscr = 'standalone class for a single TikZ figure' },
		fmta([[
		\documentclass[tikz, border=<>pt]{standalone}
		\usepackage{amsmath, amssymb}
		\usetikzlibrary{<>}

		\begin{document}
		\begin{tikzpicture}
			<>
		\end{tikzpicture}
		\end{document}
		]], {
			i(1, '5'),
			i(2, 'arrows.meta, positioning'),
			i(0),
		}),
		in_preamble
	),

--  ╔══════════════════════════════════════════════════════════╗
--  ║                     preamble blocks                      ║
--  ╚══════════════════════════════════════════════════════════╝

	s( -- the package block almost every math document wants
		{ trig = 'mathpkgs', dscr = 'standard mathematics package block' },
		fmta([[
		\usepackage{amsmath, amssymb, amsthm, mathtools}
		\usepackage{mathrsfs}
		\usepackage[hidelinks]{hyperref}
		\usepackage{cleveref}
		<>
		]], {
			i(0),
		}),
		in_preamble
	),
	s( -- amsthm declarations, shared numbering off `theorem`
		{ trig = 'thmset', dscr = 'amsthm environment declarations' },
		fmta([[
		\newtheorem{theorem}{Theorem}[<>]
		\newtheorem{lemma}[theorem]{Lemma}
		\newtheorem{proposition}[theorem]{Proposition}
		\newtheorem{corollary}[theorem]{Corollary}
		\theoremstyle{definition}
		\newtheorem{definition}[theorem]{Definition}
		\newtheorem{example}[theorem]{Example}
		\theoremstyle{remark}
		\newtheorem{remark}[theorem]{Remark}
		<>
		]], {
			i(1, 'section'),
			i(0),
		}),
		in_preamble
	),
	s( -- page geometry
		{ trig = 'geom', dscr = 'geometry margins' },
		fmta([[
		\usepackage[margin=<>]{geometry}
		<>
		]], {
			i(1, '1in'),
			i(0),
		}),
		in_preamble
	),
}
