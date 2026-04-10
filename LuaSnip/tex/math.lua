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
local r = ls.restore_node
local f = ls.function_node
local d = ls.dynamic_node
local fmt = require("luasnip.extras.fmt").fmt
local fmta = require("luasnip.extras.fmt").fmta
local rep = require("luasnip.extras").rep
local postfix = require("luasnip.extras.postfix").postfix
local line_begin = require("luasnip.extras.expand_conditions").line_begin
local helper = require('noethervim-tex.luasnip_helper')
local get_visual_node = helper.get_visual_node
local get_visual_insert_node = helper.get_visual_insert_node
local tex_utils = helper.tex_utils
local mat = helper.mat
local square_mat = helper.square_mat

-- may still be useful in the future: /Users/nathanaelchwojko-srawkey/Library/Group Containers/UBF8T346G9.SyncClientSuite/.noindex//Documents



-- ┌───────────────────────────────┐
-- │ For Further Inspiration, see: │
-- └───────────────────────────────┘
-- https://castel.dev/post/lecture-notes-1/

return
--  ┌                                                          ┐
--  │                     manual triggers                      │
--  └                                                          ┘
	{
--  ┌                                                          ┐
--  │                                                          │
--  │               regular expression triggers                │
--  │                                                          │
--  └                                                          ┘
		s(
			{ trig = "ff", wordTrig = false, dscr = "Expands 'ff' into '\\frac{}{}'" },
			fmta("<>\\frac{<>}{<>}", {
				f(function(_, snip)
					return snip.captures[1]
				end),
				d(1, get_visual_insert_node),
				i(2),
			}),
			{
				condition = tex_utils.in_mathzone,
				show_condition = tex_utils.in_mathzone,
			}
		),

		-- \frac
		s(
			{ trig = "([^%a])FF", regTrig = true, wordTrig = false, dscr = "Expands 'ff' into '\\frac{}{}'" },
			fmta("<>\\frac{<>}{<>}", {
				f(function(_, snip)
					return snip.captures[1]
				end),
				d(1, get_visual_insert_node),
				i(2),
			}),
			{
				condition = tex_utils.in_mathzone,
				show_condition = tex_utils.in_mathzone,
			}
		),

		-- exponent (e^{<>})
		s(
			{ trig = "([^%a])ee", regTrig = true, wordTrig = false, dscr = "exponent" },
			fmta("<>e^{<>}", {
				f(function(_, snip)
					return snip.captures[1]
				end),
				d(1, get_visual_insert_node),
			},
			{
				condition = tex_utils.in_mathzone,
				show_condition = tex_utils.in_mathzone,
			}
			)
		),
		-- exponent
		s(
			{ trig = "([^%a])exp", regTrig = true, wordTrig = false, dscr = "exp(<>)" },
			fmta("<>exp(<>)", {
				f(function(_, snip)
					return snip.captures[1]
				end),
				d(1, get_visual_insert_node),
			}),
			{
				condition = tex_utils.in_mathzone,
				show_condition = tex_utils.in_mathzone,
			}
		),
		-- -- mathfrak
		-- s(
		-- 	{ trig = "f", regTrig = false, wordTrig = false, dscr = "mathfrak" },
		-- 	fmta("\\mathfrak{<>}", {
		-- 		d(1, get_visual_insert_node),
		-- 	}),
		-- 	{
		-- 		condition = tex_utils.in_mathzone,
		-- 		show_condition = tex_utils.in_mathzone,
		-- 	}
		-- ),
		-- -- hat (widehat)
		-- postfix("hat", {l("\\widehat{" .. l.POSTFIX_MATCH .. "}")}, {
		-- 	condition= tex_utils.in_mathzone,
		-- 	show_condition = tex_utils.in_mathzone,
		-- }),
		-- -- bar (overline)
		-- postfix("bar", {l("\\overline{" .. l.POSTFIX_MATCH .. "}")}, {
		-- 	condition= tex_utils.in_mathzone,
		-- 	show_condition= tex_utils.in_mathzone,
		-- }),
	-- matrix snippet
	s({ trig='([bBpvV]?)mat:?(%d+)[x*](%d+)([ar]?)', regTrig=true, name='matrix', dscr='matrix trigger lets go'},
    fmta([[
    \begin{<>}<>
    <>\end{<>}]],
    { f(function (_, snip) return snip.captures[1] .. "matrix" end),
    f(function (_, snip) -- augments
        if snip.captures[4] == "a" then
            local out = string.rep("c", tonumber(snip.captures[3]) - 1)
            return "[" .. out .. "|c]"
        end
        return ""
    end),
    d(1, mat),
    f(function (_, snip) return snip.captures[1] .. "matrix" end)}
    ),
	{
		condition = tex_utils.in_mathzone,
		show_condition = tex_utils.in_mathzone,
	}
	),
	-- square matrix snippet
	s({ trig='([bBpvV]?)mat:?(%d+)([ar]?)', regTrig=true, name='matrix', dscr='square matrix'},
    fmta([[
    \begin{<>}<>
    <>\end{<>}]],
    { f(function (_, snip) return snip.captures[1] .. "matrix" end),
    f(function (_, snip) -- augments
        if snip.captures[3] == "a" then
            local out = string.rep("c", tonumber(snip.captures[2]) - 1)
            return "[" .. out .. "|c]"
        end
        return ""
    end),
    d(1, square_mat),
    f(function (_, snip) return snip.captures[1] .. "matrix" end)}
    ),
	{
		condition = tex_utils.in_mathzone,
		show_condition = tex_utils.in_mathzone,
	}
	),
},
	--  ┌                                                          ┐
	--  │                                                          │
	--  │                      --autotriggers                      │
	--  │                                                          │
	--  └                                                          ┘
{
	-- backslash
	s(
		{trig = 'BH', name = 'backslash', wordTrig=false},
		{ t('\\backslash')},
		{
			condition = tex_utils.in_mathzone,
			show_condition = tex_utils.in_mathzone
		}
	),
	-- overline
	s(
		{trig = 'BB', name = 'overline (bar)', wordTrig=false},
		{ t('\\overline{'), d(1, get_visual_insert_node), t('}') },
		{
			condition = tex_utils.in_mathzone,
			show_condition = tex_utils.in_mathzone
		}
	),
	-- create set
	s(
		{trig = '{{', name='set', dscr='set with optional set-builder notation'},
		{c(1,
		{
			sn(nil, { t('\\left\\{'), r(1, ''), t('\\right\\}') }),
			sn(nil, {t('\\set{'),r(1, ''), t('}{'), i(2), t('}')})
		})
		},
		{
			condition = tex_utils.in_mathzone,
			show_condition = tex_utils.in_mathzone,
		}
	),
	-- create fraction
	s(
		{trig = '//', name='fraction', dscr='fraction'},
		{
			t('\\frac{'),
			d(1, get_visual_node),
			t('}{'),
			i(2),
			t('}'),
			i(0)
		},
		{
			condition = tex_utils.in_mathzone,
			show_condition = tex_utils.in_mathzone,
		}
	),
	-- square brakets
	s(
		{trig = '[[', wordtrig='false', name='square brakets'},
		{t('\\left['), d(1, get_visual_node), t('\\right]')},
		{
			condition = tex_utils.in_mathzone,
			show_condition = tex_utils.in_mathzone,
		}
	),
	-- round brakets
	s(
		{trig = '((', wordtrig='false', name='Parenthesis'},
		{t('\\left('), d(1, get_visual_node), t('\\right)')},
		{
			condition = tex_utils.in_mathzone,
			show_condition = tex_utils.in_mathzone,
		}
	),
	-- abs braces
	s(
		{trig = '||', wordtrig='false', name='Parenthesis'},
		{t('\\left|'), d(1, get_visual_node), t('\\right|')},
		{
			condition = tex_utils.in_mathzone,
			show_condition = tex_utils.in_mathzone,
		}
	),
	-- angle brakets
	s(
		{trig = '<<', name='set', wordtrig='false', dscr='set with optional set-builder notation'},
		fmta([[
		\langle <> \rangle
		]],
		{i(1)}
		),
		{
			condition = tex_utils.in_mathzone,
			show_condition = tex_utils.in_mathzone,
		}
	),

	-- mapsto
	s(
		{ trig = '!>', dscr = "mapsto" },
		{t '\\mapsto'},
		{
			condition = tex_utils.in_mathzone,
			show_condition = tex_utils.in_mathzone,
		}
	),
	-- subseteq
	s(
		{ trig = 'cc', dscr = "subseteq" },
		{t '\\subseteq'},
		{
			condition = tex_utils.in_mathzone,
			show_condition = tex_utils.in_mathzone,
		}
	),
	-- supbseteq
	s(
		{ trig = 'SS', regTrig=true, wordTrig=false, dscr = "superset" },
		{t '\\supseteq'},
		{
			condition = tex_utils.in_mathzone,
			show_condition = tex_utils.in_mathzone,
		}
	),
	-- composition
	s(
		{ trig = '([%s%a%(%)%[%]%{%}%$])CC', regTrig=true, wordTrig=false, dscr = "composition (circ)" },
		{t '\\circ'},
		{
			condition = tex_utils.in_mathzone,
			show_condition = tex_utils.in_mathzone,
		}
	),
	-- sheaf of moduels
	s(
		{ trig = 'WT', dscr="sheaf of modules (widetilde)"},
		{t('\\widetilde{'), d(1, get_visual_node), t('}'), i(0)},
		{
			condition = tex_utils.in_mathzone,
			show_condition = tex_utils.in_mathzone,
		}
	),
	s(
		{ trig = 'TL', dscr="tilde"},
		{t('\\tilde{'), d(1, get_visual_node), t('}'), i(0)},
		{
			condition = tex_utils.in_mathzone,
			show_condition = tex_utils.in_mathzone,
		}
	),
	-- text
	s(
		{ trig = 'TT', dscr = "text" },
		{t('\\text{'), d(1, get_visual_node), t('}'), i(0)},
		{
			condition = tex_utils.in_mathzone,
			show_condition = tex_utils.in_mathzone,
		}
	),
	s(
		{ trig = 'QLQ', dscr = "space iff space" },
		{t('\\qquad\\LRw\\qquad ')},
		{
			condition = tex_utils.in_mathzone,
			show_condition = tex_utils.in_mathzone,
		}
	),
	-- bar
	-- s(
	-- 	{ trig = 'BB', dscr = "overline" },
	-- 	{t('\\oln{'), d(1, get_visual_node), t('}'), i(0)},
	-- 	{
	-- 		condition = tex_utils.in_mathzone,
	-- 		show_condition = tex_utils.in_mathzone,
	-- 	}
	-- ),
	-- hat
	s(
		{ trig = 'HH', dscr = "hat" },
		{t('\\hat{'), d(1, get_visual_node), t('}'), i(0)},
		{
			condition = tex_utils.in_mathzone,
			show_condition = tex_utils.in_mathzone,
		}
	),
	-- widehat
	s(
		{ trig = 'WH', dscr = "widehat" },
		{t('\\widehat{'), d(1, get_visual_node), t('}'), i(0)},
		{
			condition = tex_utils.in_mathzone,
			show_condition = tex_utils.in_mathzone,
		}
	),
	-- \[  math mode \]
	s(
		{ trig = 'kk', dscr = "inline math" },
		fmta(
		[[
		\[
			<>
		\]<>
		]],
			{ d(1, get_visual_insert_node), i(0) }
		),
		{
			-- condition = tex_utils.beginning_text,
			-- show_condition = tex_utils.beginning_text
		}
	),
	-- quad text quat
	s(
		{ trig = 'qtq', name='quad text quad' },
		fmta([[
		\qquad \text{<>} \qquad
		]],
			{ d(1, get_visual_insert_node)}
		),
		{
			condition = tex_utils.in_mathzone,
			show_condition = tex_utils.in_mathzone,
		}
	),
	-- diff
	s({ trig = "DF" , name='diff'}, { t("\\diff ") }, { condition = tex_utils.in_mathzone, show_condition = tex_utils.in_mathzone }),
	-- wedge
	s({ trig = "WW" , name='wedge'}, { t("\\wedge ") }, { condition = tex_utils.in_mathzone, show_condition = tex_utils.in_mathzone }),
	-- bullet
	s({ trig = "BL" , name='bullet'}, { t("\\bullet") }, { condition = tex_utils.in_mathzone, show_condition = tex_utils.in_mathzone }),
	-- {d}{d<>}
	s({ trig = "dV", name='d/d<>' }, fmta([[\dv{<>}]], { d(1, get_visual_node) }), { condition = tex_utils.in_mathzone, show_condition = tex_utils.in_mathzone }),
	-- underscore upright
	-- s(
	-- 	{ trig = "sd", wordTrig = false, name='underscore upright' },
	-- 	fmta("_{\\mathrm{<>}}", { d(1, get_visual_node) }),
	-- 	{
	-- 		condition = tex_utils.in_mathzone,
	-- 		show_condition = tex_utils.in_mathzone,
	-- 	}
	-- ),
	-- alignment
	s(
		{ trig = "==" , wordTrig=false, name='aligning equals', dscr='text aligns with &'},
		{t('&=')},
		{
			condition = tex_utils.in_align,
			show_condition = tex_utils.in_align,
		}
	),
	-- integral, -infty to infty
	s(
		{trig = 'intinf', name='integral, -oo, oo'},
		{
			t('\\int_{-\\infty}^{\\infty}')
		},
		{
			condition = tex_utils.in_mathzone,
			show_condition = tex_utils.in_mathzone,
		}

	),
	-- create under-script
	s(
	{trig = '__', wordTrig=false, name = 'create underscore'},
	{t('_{'), d(1, get_visual_node), t('}')},
	{
		condition = tex_utils.in_mathzone,
		show_condition = tex_utils.in_mathzone,
	}
	),
	-- create super-script
	s(
	{trig = '^^', name = 'create underscore'},
	{t('^{'), i(1), t('}')},
	{
		condition = tex_utils.in_mathzone,
		show_condition = tex_utils.in_mathzone,
	}
	),
	-- derivation
	s(
		{trig = 'der', name='derivation'},
		fmta([[
		\left.\\frac{\\partial }{\\partial <>}\right|_{<>}
		]],
		{
			i(1, 'x^i'),
			i(2)
		}
	),
	{
		condition = tex_utils.in_mathzone,
		show_condition = tex_utils.in_mathzone,
	}
	),
	-- ... -> cdots
	-- s(
	-- 	{trig = '...', name='... -> cdots'},
	-- 	{ t('\\cdots ') },
	-- {
	-- 	condition = tex_utils.in_mathzone,
	-- 	show_condition = tex_utils.in_mathzone,
	-- }
	-- ),
	-- partial fraction
	s(
		{trig = 'pf', name='partial fraction'},
		fmta([[
		\frac{\partial <>}{\partial <>}
		]],
		{
			d(1, get_visual_node),
			i(2)
		}
	),
	{
		condition = tex_utils.in_mathzone,
		show_condition = tex_utils.in_mathzone,
	}
	),
	s(
		{trig = 'pp', name='partial'},
		fmta([[
		\partial
		]],
		{}
	),
	{
		condition = tex_utils.in_mathzone,
		show_condition = tex_utils.in_mathzone,
	}
	),
	-- ->
	s(
		{trig = '->', name='\to', description = 'to arrow'},
		t('\\to'),
		{
			condition = tex_utils.in_mathzone,
			show_condition = tex_utils.in_mathzone,
		}
	),
	-- -x>
	s(
		{trig = '-x>', name='arrow with text', description = ''},
		{t('\\xrightarrow{'), d(1, get_visual_node), t('}')},
		{
			condition = tex_utils.in_mathzone,
			show_condition = tex_utils.in_mathzone,
		}
	),
	-- hookrightarrow
	s(
		{trig = '-h>', name='\\hookrightarrow', description = 'to hookrightarrow'},
		t('\\hookrightarrow'),
		{
			condition = tex_utils.in_mathzone,
			show_condition = tex_utils.in_mathzone,
		}
	),
	-- doubleheadrightarrow (surjective arrow)
	s(
		{trig = '-2>', name='\\doubleheadrightarrow', description = 'to twoheadrightarrow'},
		t('\\twoheadrightarrow'),
		{
			condition = tex_utils.in_mathzone,
			show_condition = tex_utils.in_mathzone,
		}
	),
	-- rightrightarrow (equalizer arrow)
	s(
		{trig = '-e>', name='\\rightrightarrows', description = 'equalizer arrows'},
		t('\\rightrightarrows'),
		{
			condition = tex_utils.in_mathzone,
			show_condition = tex_utils.in_mathzone,
		}
	),
	-- dashed arrow (rational maps)
	s(
		{trig = '-d>', name='\\dashrightarrow', description = 'to dashrightarrow'},
		t('\\dashrightarrow'),
		{
			condition = tex_utils.in_mathzone,
			show_condition = tex_utils.in_mathzone,
		}
	),
	-- real, integers, naturals
	-- s(
	-- 	{trig = '\\R', name='mathbb{R}', description = 'real numbers'},
	-- 	t('\\mathbb{R}'),
	-- 	{
	-- 		condition = tex_utils.in_mathzone,
	-- 		show_condition = tex_utils.in_mathzone,
	-- 	}
	-- ),
	-- == becomes &=
	s(
		{trig = '==', name='&=', description = 'align environment equals'},
		t('&='),
		{
			condition = tex_utils.in_align,
			show_condition = tex_utils.in_align,
		}
	),
	--  ╒══════════════════════════════════════════════════════════╕
	--  │                         reg-trig                         │
	--  ╘══════════════════════════════════════════════════════════╛

	-- emptyset
	s(
		{ trig = "([%s%a%(%)%[%]%{%}%$])00", regTrig = true, wordTrig = false, dscr = "emptyset" },
		fmta("<>\\emptyset", {
			f(function(_, snip)
				return snip.captures[1]
			end),
		}),
		{
			condition = tex_utils.in_mathzone,
			show_condition = tex_utils.in_mathzone,
		}
	),
	-- inline math
	s(
		{ trig = "([^%a])mm", wordTrig = false, regTrig = true, dscr = "inline math mode" },
		fmta("<>$<>$", {
			f(function(_, snip)
				return snip.captures[1]
			end),
			d(1, get_visual_node),
		}),
		{
			condition = tex_utils.in_text,
			show_condition = tex_utils.in_text,
		}
	),
	-- a_1n.. -> a_1, a_2, ... a_n
	s(
		{trig = "([%w_^]+)([01])([%w])([%S]+)?%.%.", name = 'here'},
		{
			t('not yet implimented')
		},
		{
			condition = tex_utils.in_text,
			show_condition = tex_utils.in_text,
		}

	),


	s({trig = "UU", name = 'underline'}, {
		t('\\underline{'),
		d(1, get_visual_insert_node),
		t('}'),
		i(0),
	},
	{
		condition = tex_utils.in_mathzone,
		show_condition = tex_utils.in_mathzone
	}),

}

--
-- #context "isMath()"
-- snippet "([\\a-zA-Z0-9_\^]+)([)\_\^])([01])([\w\d])([\S]+)?\.\." "create a_1, a_2, ..., a_n" r
-- `!p
-- #x_1n..\times => group(1) = x  group(2) = _  group 3 = 1 or 0, group 4 = n   group(5) = \times
-- snip.rv = match.group(1) #first element
-- snip.rv += match.group(2)+match.group(3) #( _1 or ^1 ) or (_0 or ^0)
-- snip.rv += ", " if match.group(5) is None else match.group(4) + " " #, or special symbol
-- snip.rv += match.group(1) #
-- snip.rv += match.group(2)+"2" if match.group(3) =="1" else match.group(2)+"1"
-- snip.rv += ", ..., " if match.group(5) is None else match.group(5) + " \cdots " + match.group(5) + " "
-- snip.rv += match.group(1)
-- snip.rv += match.group(2)
-- snip.rv += match.group(4)`
-- endsnippet
--
--
-- # }]}
-- # Fraction Snippets {[{
-- # ========================================================================
-- context "isMath()"
-- snippet FF "fraction"
-- \frac{${1:${VISUAL}}}{$2}$0
-- endsnippet
--
-- #context "isMath()"
-- #snippet '^.*\)/' "() Fraction" wrA
-- #`!p
-- #stripped = match.string[:-1]
-- #depth = 0
-- #i = len(stripped) - 1
-- #while True:
-- 	#if stripped[i] == ')': depth += 1
-- 	#if stripped[i] == '(': depth -= 1
-- 	#if depth == 0: break;
-- 	#i -= 1
-- #snip.rv = stripped[0:i] + "\\frac{" + stripped[i+1:-1] + "}"
-- #`{$1}$0
-- #endsnippet
--
-- #priority -1
-- #context "isMath()"
-- #snippet "([\w\'\"\\\d\_\^\(\)\{\}\[\]\+\-]+)\/([\w \'\"\\\d\_\^\(\)\{\}\[\]\+\-]+)" "fraction" r
-- #\frac{`!p snip.rv = match.group(1)`}{`!p snip.rv = match.group(2)`}
-- #endsnippet
--
-- priority -1
-- context "isMath()"
-- snippet "([\w\'\"\\\d\_\^\(\)\{\}\[\]\+\-]+)\//" "fraction" r
-- \frac{`!p snip.rv = match.group(1)`}{$1}$0
-- endsnippet
-- # }]}
--
-- # Fraction Snippets {[{
-- # ========================================================================
-- snippet sympy "sympy block " w
-- sympy $1 sympy$0
-- endsnippet
--
-- priority 10
-- snippet 'sympy(.*)sympy' "evaluate sympy" wr
-- `!p from sympy import *
-- x,y,z,t = symbols('x y z t')
-- k,m,n = symbols('k m n', integer=True)
-- f,g,h = symbols('f g h', cls=Function)
-- init_printing()
-- snip.rv = eval('latex(' + match.group(1).replace('\\','') \
-- .replace('^', '**') \
-- .replace('{','(')\
-- .replace('}', ')') + ')')`
-- endsnippet
-- # }]}
--
