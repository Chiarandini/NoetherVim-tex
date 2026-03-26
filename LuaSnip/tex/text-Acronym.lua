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
local helper = require('utils.luasnip-helper-func')
local get_visual_node = helper.get_visual_node
local get_visual_insert_node = helper.get_visual_insert_node
local tex_utils = helper.tex_utils
local mat = helper.mat

-- may still be useful in the future: /Users/nathanaelchwojko-srawkey/Library/Group Containers/UBF8T346G9.SyncClientSuite/.noindex//Documents




-- ┌───────────────────────────────┐
-- │ For Further Inspiration, see: │
-- └───────────────────────────────┘
-- https://castel.dev/post/lecture-notes-1/

-- NOTE: "bc" -> "because" is handeled by abolish for its more robust edge case
-- completion (in ftplugin/tex.lua)
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
},
	--  ┌                                                          ┐
	--  │                                                          │
	--  │                      --autotriggers                      │
	--  │                                                          │
	--  └                                                          ┘
{
	-- "The following are equivalent"
	s(
		{trig = 'tfae', name = 'the following are equivalent'},
		t('the following are equivalent')
	),
	s(
		{trig = 'Tfae', name = 'the following are equivalent'},
		t('The following are equivalent')	),
	s(
		{trig = 'TFAE', name = 'the following are equivalent'},
		t('the following are equivalent')	),
	-- "Finite dimensional vector space"
	s(
		{trig = 'fdvsp', name = 'finite dimensional vector space'},
		t('finite dimensional vector space')	),
	s(
		{trig = 'VSP', name = 'vector space', wortTrig = true},
		t('vector space')	),
	s(
		{trig = 'IPSP', name = 'inner product space'},
		t('inner product space')	),
	s(
		{trig = 'ndvsp', name = 'n dimensional vector space'},
		t('$n$ dimensional vector space')	),
	-- such that (in math)
	-- s(
	-- 	{ trig = 'st', name = '\\text{ such that }' },
	-- 	t('\\text { such that }'),
	-- 	{
	-- 		condition = tex_utils.in_mathzone,
	-- 	}
	-- ),
	-- such that (in text)
	-- s(
	-- 	{ trig = ' st ', name = 'such that' },
	-- 	t(' such that '),
	-- 	{
	-- 		condition = tex_utils.in_text
	-- 	}
	-- ),
	-- with respect to
	s(
		{trig = 'wrt', name = 'with respect to'},
		t('with respect to')	),
	-- as we sought to show
	s(
		{trig = 'awsts', name = 'as we sought to show'},
		t('as we sought to show')	),
	-- completing the proof
	s(
		{trig = 'ctp', name = 'completing the proof'},
		t('completing the proof')	),
	-- without loss of generality
	s(
		{trig = 'wlog', name = 'without loss of generality'},
		t('without loss of generality')	),
	s(
		{trig = 'WLOG', name = 'Without loss of generality'},
		t('Without loss of generality')	),
	s( -- short exact sequence
		{trig = 'SES', name = 'short exact sequence'},
		t('short exact sequence')	),
	s( -- long exact sequence
		{trig = 'LES', name = 'long exact sequence'},
		t('long exact sequence')	),
	s( -- exact sequence
		{trig = 'EES', name = 'exact sequence'},
		t('exact sequence')	),
	s( -- for the sake of contradiction
	{trig = 'ftsoc', name = 'for the sake of contradiction'},
	t('for the sake of contradiction')	),
	s(
	{trig = 'FTSOC', name = 'For the sake of contradiction'},
	t('For the sake of contradiction')	),
	-- On the other hand
	s(
	{trig = 'OTOH', name = 'On the other hand'},
	t('On the other hand')	),
	-- left hand side
	s(
	{trig = 'LHS', name = 'left hand side'},
	t('left hand side')	),
	-- right hand side
	s(
	{trig = 'RHS', name = 'right hand side'},
	t('right hand side')	),
	-- left hand side
	s(
	{trig = 'RRR', name = 'ref:HERE'},
	t('\\textcolor{red}{ref:HERE}')	),
	-- otoh
	s(
	{trig = 'otoh', name = 'on the other hand'},
	t('on the other hand')	),
	-- finitely generated
	s(
		{trig = 'fg', name=  'finitely generated'},
		t('finitely generated'),
		{
			condition = tex_utils.in_text
		}
	),
	-- finitely dimensional
	s(
		{trig = 'fdim', name=  'finitely dimensional'},
		t('finite dimensional')	),
	-- "if and only if"
	s(
		{trig = 'iff', name = 'if and only if'},
		t('if and only if'),
		{
			condition = tex_utils.in_text
		}
		),
	-- "if and only if"
	s(
		{trig = 'iff', name = 'if and only if'},
		t('\\text{ if and only if }'),
		{
			condition = tex_utils.in_mathzone
		}
		),
	-- Fix ">" to "." mistake
	-- s(
	-- 	{trig = '>', wortTrig=false, name = 'if and only if'},
	-- 	t('.'),
	-- 	{
	-- 		condition = tex_utils.in_text
	-- 	}
	-- 	),

--  ╒══════════════════════════════════════════════════════════╕
--  │                         reg-trig                         │
--  ╘══════════════════════════════════════════════════════════╛

	-- such that (in text)
	s(
		{trig = '(%s+)st ', regTrig=true, wortTrig=false, name = 'such that'},
		{
			f(function(_, snip) return snip.captures[1] end),
			t('such that '),
		}
	),
	s(
		{trig = "<", name ="shift comma"},
		{t(",")},
		{
			condition = tex_utils.in_text
		}
	),
	s(
		{trig = ">", name ="shift dot"},
		{t(".")},
		{
			condition = tex_utils.in_text
		}
	),

}
