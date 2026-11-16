-- utils.lua
-- Common utilities for whitespace detection and processing.

local constants = require("detect_whitespace.constants")

local M = {}

-- Split a carriage return off the end of a line.
--
-- A CRLF file opened with 'fileformat' set to unix, or read from disk, yields
-- lines that end with "\r". The "\r" is part of the line ending, not
-- whitespace, so it is kept aside and never removed.
--
-- @param line (string): Line to split.
-- @return string, string: line body and the trailing "\r" (or "").
function M.split_cr(line)
  if line:sub(-1) == "\r" then
    return line:sub(1, -2), "\r"
  end
  return line, ""
end

-- Find the byte index where trailing whitespace starts.
--
-- Whitespace characters are compared as whole characters, so bytes inside
-- multibyte characters are never mistaken for whitespace.
--
-- @param body (string): Line without a line ending.
-- @return number|nil: 1-indexed start byte, or nil if there is none.
local function trailing_start(body)
  local pos = #body + 1
  local found = true
  while found and pos > 1 do
    found = false
    for _, ws in ipairs(constants.WHITESPACE_CHARS) do
      local len = #ws
      if pos - len >= 1 and body:sub(pos - len, pos - 1) == ws then
        pos = pos - len
        found = true
        break
      end
    end
  end
  if pos <= #body then
    return pos
  end
  return nil
end

-- Check if a line contains unnecessary whitespace.
--
-- Trailing whitespace and whitespace-only lines are both reported; a
-- whitespace-only line is a line whose trailing whitespace starts at column 1.
--
-- @param line (string): Line to check.
-- @return boolean: true if the line has unnecessary whitespace.
function M.has_unnecessary_whitespace(line)
  local body = M.split_cr(line)
  return trailing_start(body) ~= nil
end

-- Find positions of unnecessary whitespace in a line.
-- Returns positions suitable for highlighting.
--
-- @param line (string): Line to check.
-- @return table: list of {start_col, end_col} pairs (1-indexed, byte based).
function M.find_whitespace_positions(line)
  local positions = {}
  local body = M.split_cr(line)
  local start_col = trailing_start(body)
  if start_col then
    table.insert(positions, { start_col = start_col, end_col = #body })
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

-- Read a file on disk, keeping each line's original line ending.
--
-- The file is opened in binary mode so that no newline conversion happens on
-- Windows, where text mode turns "\n" into "\r\n" on write and drops "\r"
-- on read.
--
-- @param path (string): file path.
-- @return table|nil, table|nil: line bodies and their line endings
--   ("\r\n", "\n", or "" for a last line without a newline),
--   or nil if the file cannot be read.
function M.read_file(path)
  -- Skip directories.
  if M.is_directory(path) then
    return nil
  end

  local file = io.open(path, "rb")
  if not file then
    return nil
  end
  local content = file:read("*a")
  file:close()

  local lines, eols = {}, {}
  local pos = 1
  while pos <= #content do
    local nl = content:find("\n", pos, true)
    local raw, eol
    if nl then
      raw = content:sub(pos, nl - 1)
      eol = "\n"
      pos = nl + 1
    else
      raw = content:sub(pos)
      eol = ""
      pos = #content + 1
    end
    local body, cr = M.split_cr(raw)
    if eol == "\n" then
      eol = cr .. eol
    else
      -- A lone "\r" at end of file without "\n" is kept as content.
      body = raw
    end
    table.insert(lines, body)
    table.insert(eols, eol)
  end

  return lines, eols
end

-- Get lines from a file on disk.
-- Line endings ("\n" and "\r\n") are not included in the returned lines.
-- Returns nil if file cannot be read.
--
-- @param path (string): file path.
-- @return table|nil: list of lines, or nil if file cannot be read.
function M.get_file_lines(path)
  local lines = M.read_file(path)
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
--   - Keeps a trailing "\r" (part of a CRLF line ending) in place.
--
-- @param line (string): Line to normalize.
-- @return string: Normalized line.
function M.normalize_line(line)
  local body, cr = M.split_cr(line)
  local start_col = trailing_start(body)
  if start_col then
    body = body:sub(1, start_col - 1)
  end
  return body .. cr
end

return M
