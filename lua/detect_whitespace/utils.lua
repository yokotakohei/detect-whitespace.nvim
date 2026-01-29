-- utils.lua
-- Common utilities for whitespace detection and processing.

local constants = require("detect_whitespace.constants")

local M = {}

-- Check if a line contains unnecessary whitespace.
--
-- @param line (string): Line to check.
-- @return boolean: true if the line has unnecessary whitespace.
function M.has_unnecessary_whitespace(line)
  -- Check for trailing whitespace.
  if line:match(constants.TRAILING_PATTERN) then
    return true
  end

  -- Check for whitespace-only lines.
  if line:match(constants.BLANK_WITH_SPACE_PATTERN) then
    return true
  end

  return false
end

-- Find positions of unnecessary whitespace in a line.
-- Returns positions suitable for highlighting.
--
-- @param line (string): Line to check.
-- @return table: list of {start_col, end_col} pairs (1-indexed).
function M.find_whitespace_positions(line)
  local positions = {}

  -- Check for trailing whitespace.
  local start_col, end_col = line:find(constants.TRAILING_PATTERN)
  if start_col then
    table.insert(positions, { start_col = start_col, end_col = end_col })
  end

  -- Check for whitespace-only lines.
  start_col, end_col = line:find(constants.BLANK_WITH_SPACE_PATTERN)
  if start_col then
    -- Only add if not already added by trailing pattern check.
    local already_added = false
    for _, pos in ipairs(positions) do
      if pos.start_col == start_col and pos.end_col == end_col then
        already_added = true
        break
      end
    end
    if not already_added then
      table.insert(positions, { start_col = start_col, end_col = end_col })
    end
  end

  return positions
end

-- Check if a file is loaded in a buffer.
--
-- @param path (string): file path.
-- @return number|nil: buffer number if loaded, nil otherwise.
function M.get_buffer_for_file(path)
  local bufnr = vim.fn.bufnr(path)
  if bufnr ~= -1 and vim.api.nvim_buf_is_loaded(bufnr) then
    return bufnr
  end
  return nil
end

-- Check if a path is a directory.
--
-- @param path (string): file path.
-- @return boolean: true if path is a directory.
function M.is_directory(path)
  local stat = vim.loop.fs_stat(path)
  return stat and stat.type == "directory" or false
end

-- Get lines from a buffer.
--
-- @param bufnr (number): buffer number.
-- @return table: list of lines.
function M.get_buffer_lines(bufnr)
  return vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
end

-- Get lines from a file on disk.
-- Returns nil if file cannot be read.
--
-- @param path (string): file path.
-- @return table|nil: list of lines, or nil if file cannot be read.
function M.get_file_lines(path)
  -- Skip directories.
  if M.is_directory(path) then
    return nil
  end

  local file = io.open(path, "r")
  if not file then
    return nil
  end

  local lines = {}
  for line in file:lines() do
    table.insert(lines, line)
  end

  file:close()
  return lines
end

-- Get lines from a file, preferring buffer content if loaded.
-- This ensures we work with the most current content, including unsaved changes.
--
-- @param path (string): file path.
-- @return table|nil: list of lines, or nil if file cannot be read.
function M.get_lines(path)
  local bufnr = M.get_buffer_for_file(path)
  if bufnr then
    return M.get_buffer_lines(bufnr)
  else
    return M.get_file_lines(path)
  end
end

-- Normalize whitespace in a single line.
--
-- Rules:
--   - Removes trailing whitespace.
--   - Converts whitespace-only lines to empty lines.
--
-- @param line (string): Line to normalize.
-- @return string: Normalized line.
function M.normalize_line(line)
  -- Remove trailing whitespace first.
  local normalized = line:gsub(constants.TRAILING_PATTERN, "")

  -- Convert whitespace-only lines to empty lines.
  if normalized:match(constants.BLANK_WITH_SPACE_PATTERN) then
    normalized = ""
  end

  return normalized
end

return M
