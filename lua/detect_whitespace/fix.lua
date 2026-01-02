-- fix.lua
-- Implements in-place whitespace normalization.
-- Line structure is preserved; only whitespace is modified.

local M = {}

-- Matches trailing whitespace
local TRAILING_PATTERN = "[\t 　]+$"

-- Matches lines containing only whitespace
local BLANK_WITH_SPACE_PATTERN = "^[\t 　]+$"

-- Normalize whitespace in a single line
--
-- Rules:
--   - Removes trailing whitespace
--   - Converts whitespace-only lines to empty lines
--
-- @param line (string): Line to normalize
-- @return string: Normalized line
function M.normalize_line(line)
  -- Remove trailing whitespace first
  local normalized = line:gsub(TRAILING_PATTERN, "")

  -- Convert whitespace-only lines to empty lines
  if normalized:match(BLANK_WITH_SPACE_PATTERN) then
    normalized = ""
  end

  return normalized
end

-- Fix a single file on disk.
--
-- Rules:
--   - Trailing whitespace is removed
--   - Whitespace-only lines become empty lines
--   - Line count is preserved
--
-- @param path (string): file path
-- @return boolean: true if the file was modified
function M.fix_file(path)
  local file = io.open(path, "r")
  if not file then
    return false
  end

  local lines = {}
  local modified = false

  -- Normalize each line independently
  for line in file:lines() do
    -- Normalize the line
    local new_line = M.normalize_line(line)

    -- Check if the line was modified
    if new_line ~= line then
      modified = true
    end

    table.insert(lines, new_line)
  end

  file:close()

  -- Avoid rewriting files if no changes were made
  if not modified then
    return false
  end

  local out = io.open(path, "w")
  if not out then
    return false
  end

  -- Write all lines back, preserving line count
  for _, l in ipairs(lines) do
    out:write(l, "\n")
  end

  out:close()
  return true
end

-- Fix multiple files sequentially
-- @param files (table)
-- @return number: count of modified files
function M.fix_files(files)
  local fixed = 0

  for _, path in ipairs(files) do
    if M.fix_file(path) then
      fixed = fixed + 1
    end
  end

  return fixed
end

return M
