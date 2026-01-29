-- constants.lua
-- Shared constants used across the plugin

local M = {}

-- Matches trailing whitespace at the end of a line
M.TRAILING_PATTERN = "[\t 　]+$"

-- Matches lines consisting solely of whitespace characters
M.BLANK_WITH_SPACE_PATTERN = "^[\t 　]+$"

return M