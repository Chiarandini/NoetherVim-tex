-- noethervim-tex.accent_spell.decoder
--
-- Decodes a LaTeX-accented token to its Unicode form, e.g.
--   K\"ahler   -> Kähler
--   Erd\H{o}s  -> Erdős
--   Poincar\'e -> Poincaré
--   r\'esum\'e -> résumé
--   na\"ive    -> naïve
--   \'etal\'e  -> étalé
--
-- Returns nil if the token contains a backslash macro the decoder
-- doesn't recognise.  Callers should treat nil as "don't flag this
-- token" -- it's the conservative default that avoids false positives
-- on inputs with unfamiliar commands.
--
-- The (accent, letter) -> Unicode table is a faithful copy of vimtex's
-- s:map_accents (autoload/vimtex/syntax/core.vim ~line 2430), so any
-- accent vimtex understands round-trips correctly through this module.

---@class noethervim_tex.AccentDecoder
local M = {}

-- Accent-macro key in the order vimtex's columns appear, so the row
-- table below stays a verbatim copy of the upstream data.
local ACCENT_KEYS = {
  "`", "'", "^", '"', "~", ".", "=", "c", "H", "k", "r", "u", "v",
}

-- letter, then 13 Unicode targets (or "" if the combination is undefined).
-- The "letter" string is the LaTeX argument: a single ASCII letter, or
-- the special token "\\i" for dotless i.
local ROWS = {
  { "a",  "à","á","â","ä","ã","ȧ","ā","" ,"" ,"ą","å","ă","ǎ" },
  { "A",  "À","Á","Â","Ä","Ã","Ȧ","Ā","" ,"" ,"Ą","Å","Ă","Ǎ" },
  { "c",  "" ,"ć","ĉ","" ,"" ,"ċ","" ,"ç","" ,"" ,"" ,"" ,"č" },
  { "C",  "" ,"Ć","Ĉ","" ,"" ,"Ċ","" ,"Ç","" ,"" ,"" ,"" ,"Č" },
  { "d",  "" ,"" ,"" ,"" ,"" ,"" ,"" ,"" ,"" ,"" ,"" ,"" ,"ď" },
  { "D",  "" ,"" ,"" ,"" ,"" ,"" ,"" ,"" ,"" ,"" ,"" ,"" ,"Ď" },
  { "e",  "è","é","ê","ë","ẽ","ė","ē","ȩ","" ,"ę","" ,"ĕ","ě" },
  { "E",  "È","É","Ê","Ë","Ẽ","Ė","Ē","Ȩ","" ,"Ę","" ,"Ĕ","Ě" },
  { "g",  "" ,"ǵ","ĝ","" ,"" ,"ġ","" ,"ģ","" ,"" ,"" ,"ğ","ǧ" },
  { "G",  "" ,"Ǵ","Ĝ","" ,"" ,"Ġ","" ,"Ģ","" ,"" ,"" ,"Ğ","Ǧ" },
  { "h",  "" ,"" ,"ĥ","" ,"" ,"" ,"" ,"" ,"" ,"" ,"" ,"" ,"ȟ" },
  { "H",  "" ,"" ,"" ,"" ,"" ,"" ,"" ,"" ,"" ,"" ,"" ,"" ,"Ȟ" },
  { "i",  "ì","í","î","ï","ĩ","į","ī","" ,"" ,"į","" ,"ĭ","ǐ" },
  { "I",  "Ì","Í","Î","Ï","Ĩ","İ","Ī","" ,"" ,"Į","" ,"Ĭ","Ǐ" },
  { "J",  "" ,"" ,"" ,"" ,"" ,"" ,"" ,"" ,"" ,"" ,"" ,"" ,"ǰ" },
  { "k",  "" ,"" ,"" ,"" ,"" ,"" ,"" ,"ķ","" ,"" ,"" ,"" ,"ǩ" },
  { "K",  "" ,"" ,"" ,"" ,"" ,"" ,"" ,"Ķ","" ,"" ,"" ,"" ,"Ǩ" },
  { "l",  "" ,"ĺ","ľ","" ,"" ,"" ,"" ,"ļ","" ,"" ,"" ,"" ,"ľ" },
  { "L",  "" ,"Ĺ","Ľ","" ,"" ,"" ,"" ,"Ļ","" ,"" ,"" ,"" ,"Ľ" },
  { "n",  "" ,"ń","" ,"" ,"ñ","" ,"" ,"ņ","" ,"" ,"" ,"" ,"ň" },
  { "N",  "" ,"Ń","" ,"" ,"Ñ","" ,"" ,"Ņ","" ,"" ,"" ,"" ,"Ň" },
  { "o",  "ò","ó","ô","ö","õ","ȯ","ō","" ,"ő","ǫ","" ,"ŏ","ǒ" },
  { "O",  "Ò","Ó","Ô","Ö","Õ","Ȯ","Ō","" ,"Ő","Ǫ","" ,"Ŏ","Ǒ" },
  { "r",  "" ,"ŕ","" ,"" ,"" ,"" ,"" ,"ŗ","" ,"" ,"" ,"" ,"ř" },
  { "R",  "" ,"Ŕ","" ,"" ,"" ,"" ,"" ,"Ŗ","" ,"" ,"" ,"" ,"Ř" },
  { "s",  "" ,"ś","ŝ","" ,"" ,"" ,"" ,"ş","" ,"ȿ","" ,"" ,"š" },
  { "S",  "" ,"Ś","Ŝ","" ,"" ,"" ,"" ,"Ş","" ,"" ,"" ,"" ,"Š" },
  { "t",  "" ,"" ,"" ,"" ,"" ,"" ,"" ,"ţ","" ,"" ,"" ,"" ,"ť" },
  { "T",  "" ,"" ,"" ,"" ,"" ,"" ,"" ,"Ţ","" ,"" ,"" ,"" ,"Ť" },
  { "u",  "ù","ú","û","ü","ũ","" ,"ū","" ,"ű","ų","ů","ŭ","ǔ" },
  { "U",  "Ù","Ú","Û","Ü","Ũ","" ,"Ū","" ,"Ű","Ų","Ů","Ŭ","Ǔ" },
  { "w",  "" ,"" ,"ŵ","" ,"" ,"" ,"" ,"" ,"" ,"" ,"" ,"" ,""  },
  { "W",  "" ,"" ,"Ŵ","" ,"" ,"" ,"" ,"" ,"" ,"" ,"" ,"" ,""  },
  { "y",  "ỳ","ý","ŷ","ÿ","ỹ","" ,"" ,"" ,"" ,"" ,"" ,"" ,""  },
  { "Y",  "Ỳ","Ý","Ŷ","Ÿ","Ỹ","" ,"" ,"" ,"" ,"" ,"" ,"" ,""  },
  { "z",  "" ,"ź","" ,"" ,"" ,"ż","" ,"" ,"" ,"" ,"" ,"" ,"ž" },
  { "Z",  "" ,"Ź","" ,"" ,"" ,"Ż","" ,"" ,"" ,"" ,"" ,"" ,"Ž" },
  { "\\i","ì","í","î","ï","ĩ","į","" ,"" ,"" ,"" ,"" ,"ĭ",""  },
}

-- key:  accent .. letter   (e.g. '"a',  'Ho',  '"\\i')
-- value: Unicode replacement
local LOOKUP = {}

local function rebuild_lookup()
  LOOKUP = {}
  for _, row in ipairs(ROWS) do
    local letter = row[1]
    for col = 2, 14 do
      local target = row[col]
      if target ~= "" then
        LOOKUP[ACCENT_KEYS[col - 1] .. letter] = target
      end
    end
  end
  -- Standalone dotless letters.
  LOOKUP["\\i"] = "ı"
  LOOKUP["\\j"] = "ȷ"
end
rebuild_lookup()

-- Punctuation accents: usable as bare \"a or braced \"{a}.
local PUNCT_ACCENTS = "`'^\"~.="

-- Letter accents: only valid braced (\H{o}, \v{c}); a bare \H is not
-- an accent macro by itself.
local LETTER_ACCENTS = "cHkruv"

local function is_in(haystack, needle)
  return haystack:find(needle, 1, true) ~= nil
end

-- Read the LaTeX target inside  {...}  -- either a single letter or \i / \j.
-- Returns the canonical letter form ("a", "\\i") or nil.
local function parse_braced_target(inner)
  if #inner == 1 and inner:match("[A-Za-z]") then
    return inner
  end
  if inner == "\\i" or inner == "\\j" then
    return inner
  end
  return nil
end

---Decode a raw LaTeX-accented token to its Unicode form.
---@param raw string  e.g. "K\\\"ahler", "Erd\\H{o}s"
---@return string|nil  Unicode form, or nil if any backslash macro is
---unrecognised.  Empty input returns "".
function M.decode(raw)
  if raw == nil or raw == "" then
    return raw
  end

  local out = {}
  local i = 1
  local n = #raw

  while i <= n do
    local c = raw:sub(i, i)

    if c ~= "\\" then
      out[#out + 1] = c
      i = i + 1
    else
      if i == n then return nil end
      local accent = raw:sub(i + 1, i + 1)

      if is_in(PUNCT_ACCENTS, accent) then
        local after = raw:sub(i + 2, i + 2)
        if after == "{" then
          local close = raw:find("}", i + 3, true)
          if not close then return nil end
          local target = parse_braced_target(raw:sub(i + 3, close - 1))
          if not target then return nil end
          local rep = LOOKUP[accent .. target]
          if not rep then return nil end
          out[#out + 1] = rep
          i = close + 1
        elseif after == "\\" then
          -- \"\i  or  \"\j
          if i + 3 > n then return nil end
          local letter = raw:sub(i + 3, i + 3)
          if letter ~= "i" and letter ~= "j" then return nil end
          local rep = LOOKUP[accent .. "\\" .. letter]
          if not rep then return nil end
          out[#out + 1] = rep
          i = i + 4
        elseif after:match("[A-Za-z]") then
          local rep = LOOKUP[accent .. after]
          if not rep then return nil end
          out[#out + 1] = rep
          i = i + 3
        else
          return nil
        end
      elseif is_in(LETTER_ACCENTS, accent) then
        -- \H{o} only -- no bare form.
        if raw:sub(i + 2, i + 2) ~= "{" then return nil end
        local close = raw:find("}", i + 3, true)
        if not close then return nil end
        local target = parse_braced_target(raw:sub(i + 3, close - 1))
        if not target then return nil end
        local rep = LOOKUP[accent .. target]
        if not rep then return nil end
        out[#out + 1] = rep
        i = close + 1
      elseif accent == "i" or accent == "j" then
        -- Standalone \i  or  \j .
        out[#out + 1] = LOOKUP["\\" .. accent]
        i = i + 2
      else
        return nil
      end
    end
  end

  return table.concat(out)
end

---Extend the lookup table with custom (accent .. letter) -> Unicode pairs.
---Used by  setup({ accent_spell = { decoder_extras = ... } }) .
---@param extras table<string, string>  e.g. { ['"y'] = 'ÿ' }
function M.extend(extras)
  for key, value in pairs(extras or {}) do
    LOOKUP[key] = value
  end
end

---Reset the lookup table to ship defaults.  Test-only entry point.
function M._reset()
  rebuild_lookup()
end

---Internal access for tests / debugging.
---@return table<string, string>
function M._lookup()
  local copy = {}
  for k, v in pairs(LOOKUP) do copy[k] = v end
  return copy
end

return M
