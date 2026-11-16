-- constants.lua
-- Shared constants used across the plugin

local M = {}

-- Characters treated as whitespace.
--
-- Each entry is a complete character, not a byte. Lua patterns work on bytes,
-- so a multibyte character such as the full-width space (U+3000, E3 80 80)
-- must not be placed in a character class like "[\t 　]": the class would
-- match the individual bytes E3 and 80, which also appear inside other
-- characters (e.g. "ダ" = E3 83 80), and stripping them corrupts UTF-8.
M.WHITESPACE_CHARS = {
  " ",      -- space
  "\t",     -- tab
  "\u{3000}", -- full-width space
}

return M
