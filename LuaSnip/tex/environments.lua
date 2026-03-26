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
local d = ls.dynamic_node
local fmt = require("luasnip.extras.fmt").fmt
local fmta = require("luasnip.extras.fmt").fmta
local rep = require("luasnip.extras").rep
local line_begin = require("luasnip.extras.expand_conditions").line_begin
local helper = require('utils.luasnip-helper-func')
local get_visual = helper.get_visual_node
local get_visual_insert = helper.get_visual_insert_node
local tex_utils = helper.tex_utils

-- NOTE: For Debugging Purposes
---@diagnostic disable-next-line: unused-function
local function serialize(tabl)
  local serializedValues = {}
  local value, serializedValue
  for entry=1,#tabl do
    value = tabl[entry]
    serializedValue = type(value)=='table' and serialize(value) or value
    table.insert(serializedValues, serializedValue)
  end
  return string.format("{ %s }", table.concat(serializedValues, ', ') )
end


-- ┌───────────────────────────────┐
-- │ For Further Inspiration, see: │
-- └───────────────────────────────┘
-- https://castel.dev/post/lecture-notes-1/

-- capitalize title and remove white space
local function makeTitle(args, parent)
	return sn(nil,{ i(1,helper.titlecase(parent.snippet.captures[1]):match('^%s*(.*%S)') or 'Environment Title')})
end


-- make first word capitalized except the first, delete white space, preserve Roman
-- numbers capitalization
local function makeTitleRef(args, parent)
	local label_text =  helper.makeRefTag(parent.snippet.captures[1])
	-- if label_text == '' or l then
	-- 	return 'label'
	-- end
	return sn(nil, {i(1, label_text)})
end

-- to not repeat between many environments
local regTrigger = '([:%w-\'%$%(%)%[%]%s,]*)'

return
--  ┌                                                          ┐
--  │                     manual triggers                      │
--  └                                                          ┘
	{
	-- 	-- Equation
	-- 	s(
	-- 		{ trig = "eq", dscr = "Expands 'eq' into an equation environment" },
	-- 		fmta(
	-- 			[[
 --       \begin{equation*}
 --           <>
 --       \end{equation*}
 --     ]],
	-- 			{ i(1) }
	-- 		)
	-- 	),
		--new environment
		s(
			{ trig = ":([%w%*]+%s?)", regTrig = true, wordTrig = true, dscr = "new environment",priority =100},
			fmta(
				[[
				\begin{<>}
					<><>
				\end{<>}
				]],
				{
					f(function(_, snip) return snip.captures[1] end),
					d(1, get_visual), i(0),
					f(function(_, snip) return snip.captures[1] end),
				}
			)	),
	-- 	--new inline environment
	-- 	s(
	-- 		{ trig = "::([%w%*]+%s?)", regTrig = true, wordTrig = false, dscr = "new environment",priority =100},
	-- 		-- { trig = ":([%w%*]+%s?)", regTrig = true, wordTrig = false, dscr = "new environment",priority =100},
	-- 		fmta(
	-- 			[[
	-- 	\begin{<>}
	-- 		<><>
	-- 	\end{<>}
	-- 	]],
	-- 			{
	-- 				f(function(_, snip) return snip.captures[1] end),
	-- 				d(1, helper.get_visual), i(0),
	-- 				f(function(_, snip) return snip.captures[1] end),
	-- 			}
	-- 		),
	-- 		{
	-- 			-- from source code: line_begin(line_to_cursor, matched_trigger)
	-- 			-- condition = function(lin_to_cur, matched) return not line_begin(lin_to_cur, matched) end,
	-- 			-- show_condition = function(lin_to_cur, matched) return not line_begin(lin_to_cur, matched) end,
	-- 		}
	-- 	),
	-- 	-- create table
	-- 	-- s({trig = "table", name='Tabular environment', dscr='automatically create tabular environment given optional input (ex. [c c c])'},
	-- 	-- {
	-- 	-- 	t"\\begin{tabular}{",
	-- 	-- 	i(1,"opts"),
	-- 	-- 	t{"}",""},
	-- 	-- 	d(2, helper.table_node, {1}, {}),
	-- 	-- 	d(3, helper.rec_table, {1}),
	-- 	-- 	t{"","\\end{tabular}"}
	-- 	-- }),
	--
	--
	-- 	-- theorem environemnt
		s(
			{ trig = ':thm%s?' .. regTrigger, regTrig = true, wordTrig= false, name = 'Create Theorem', dscr = 'Create theorem with auto-generated tag and optional Proof Environment (and conceal label)' },
			fmta([[
			\begin{thm}{<>}{<>}
				<>
			\end{thm}

			<>
			]],
			{
				d(2, makeTitle), d(3, makeTitleRef),
				d(1, get_visual_insert),
				c(4, {
					sn( nil,
					{
					t({ '\\begin{Proof}', '\t' }),
						i(1),
					t({ '', '\\end{Proof}' })
					}),
					i(1)
				}),
			}
			)
		),
	--
	-- 	-- definition environment
		s(
			{ trig = ":defn%s?" .. regTrigger, regTrig = true, wordTrig= false, name = 'Create Definition', dscr = 'Create definition with auto-generated tag (and conceal label)' },
			fmta([[
				\index{<>}
				\begin{defn}{<>}{<>}
					<>
				\end{defn}

				<>
				]],
				{
					d(4, makeTitle),
					d(2, makeTitle), d(3, makeTitleRef),
					d(1, get_visual_insert),
					i(0),
				}
				)
			),
	--
	-- 	-- proposition environment
		s(
			{ trig = ":prop%s?" .. regTrigger, regTrig = true, wordTrig= false, name = 'Create Proposition', dscr = 'Create proposition with auto-generated tag and Proof environment (and conceal label)' },
			fmta([[
			\begin{prop}{<>}{<>}
				<>
			\end{prop}

			\begin{Proof}
				<>
			\end{Proof}
			]],
			{
				d(2, makeTitle), d(3, makeTitleRef),
				d(1, get_visual_insert),
				i(0),
			}
			)		),
	--
	-- 	-- corollary environment
		s(
			{ trig = ':cor%s?' .. regTrigger, regTrig = true, wordTrig= false, name = 'Create Corollary', dscr = 'Create corollary with auto-generated tag and Proof environment (and conceal label)' },
			fmta([[
			\begin{cor}{<>}{<>}
				<>
			\end{cor}

			\begin{Proof}
				<>
			\end{Proof}
			]],
			{
				d(2, makeTitle), d(3, makeTitleRef),
				i(1),
				i(0),
			}
			)		),


		-- lemma environment
		s(
			{ trig = ":lem%s?" .. regTrigger, regTrig = true, wordTrig= false, name = 'Create Lemma', dscr = 'Create lemma with auto-generated tag and Proof environment (and conceal label)' },
			fmta([[
			\begin{lem}{<>}{<>}
				<>
			\end{lem}

			\begin{Proof}
				<>
			\end{Proof}
			]],
			{
				d(2, makeTitle), d(3, makeTitleRef),
				d(1, get_visual_insert),
				i(0),
			}
			)		),

		-- example
		s(
			{trig = ':example%s?' .. regTrigger, regTrig=true, name='example environment'},
			fmta([[
			\begin{example}{<>}{<>}
				<>
			\end{example}
			]],
			{
				d(1, makeTitle), d(2, makeTitleRef),
				d(3, get_visual_insert),
			}
			)		),
		-- exercise
		s(
			{trig = ':exercise', regTrig=true, name='exercise environment'},
			fmta([[
			\begin{Exercise}[label=qu:<>]
			  \Question <>
			\end{Exercise}
			\begin{Answer}[ref={qu:<>}]
			  \Question
			\end{Answer}
			]],
			{
				i(1), i(0), rep(1)
			}),
			{
				condition = line_begin,
				show_condition = helper.at_line_start_tcolor,
			}
		),

		s(
			{ trig = ':box%s?' .. regTrigger, regTrig = true, wordTrig= false, name = 'Create TitledBox', dscr = 'Create a box with auto-generated tag ' },
			fmta([[
			\begin{titledBox}{<>}{<>}
				<>
			\end{titledBox}
			]],
			{
				d(2, makeTitle), d(3, makeTitleRef),
				d(1, get_visual_insert),
			}
			)
		),
	},
	--  ┌                                                          ┐
	--  │                                                          │
	--  │                      --autotriggers                      │
	--  │                                                          │
	--  └                                                          ┘
	{
		s(
			{ trig = "ENV" },
			fmta(
				[[
				  \begin{<>}
					  <>
				  \end{<>}
				]],
				{
					i(1),
				d(2, get_visual_insert),
					rep(1), -- this node repeats insert node i(1)
				}
			)		),
		-- equation
		s(
			{ trig = 'nn', name = "equation" },
			fmta(
				[[
				\begin{equation}
					<>
				\end{equation}
			]],
				{ d(1, get_visual_insert) }
			),
			{
				condition = tex_utils.beginning_text,
				show_condition = tex_utils.in_document
			}
		),
		-- align*
		s(
			{ trig = "EAS", name='align*' },
			fmta(
				[[
				  \begin{align*}
					  <>
				  \end{align*}
				]],
				{
				  d(1, get_visual_insert)
				}
			)		),
	-- enumerate
	s(
		{ trig = "EEN", name='enumerate' },
		fmta(
			[[
			\begin{enumerate}
				\item <>
			\end{enumerate}
			]],
				{
					-- to insure no extra tabs where selected
					-- d(1, helper.get_visual_space_insert_node),
					d(1, helper.get_visual_insert_node),
				}
			)
		),
	-- enumerate
	s(
		{ trig = "EEE", name='enumerate' },
		fmta(
			[[
			\begin{equivEnumerate}
				\item[($\Rw$)] <>
			\end{equivEnumerate}
			]],
				{
					-- to insure no extra tabs where selected
					-- d(1, helper.get_visual_space_insert_node),
					d(1, helper.get_visual_insert_node),
				}
			)
		),
	-- itemize
	s(
		{ trig = "EIT", name='itemize' },
	fmta([[
		\begin{itemize}
			\item <>
		\end{itemize} ]],
		{ d(1, get_visual_insert),}
	),
	{
		condition = tex_utils.in_text,
		show_condition = tex_utils.in_text,
	}

	),
	-- figure
	s(
		{ trig = "FIG", name='figure' },
	fmta([[
		\begin{figure}[H]
		  \centering
		  \includegraphics[width=<>cm]{<>}
		  \caption{<>}
		  \label{<>}
		\end{figure}
		]], {
		i(1, '7'),
		i(2, '../images'), -- would add / if auto opened cmenu
		i(3),
		i(4, 'fig:')
	})	),
	s( -- ISSUE: error in calling this, subfigure
		{ trig = "(%d)SFIG", name='sub-figure', regTrig=true },
	fmta([[
		\begin{figure}[H]
		  \centering
		  <>
		  \caption{<>}
		  \label{<>}
		\end{figure}
		]], {
		d(1, helper.subfigures),
		i(2),
		i(3, 'fig:')
	})	),
}
