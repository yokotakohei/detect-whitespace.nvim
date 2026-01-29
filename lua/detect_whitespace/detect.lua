-- detect.lua
-- Implements read-only detection logic for unnecessary whitespace.
-- No file modifications are performed in this module.

local utils = require("detect_whitespace.utils")

local M = {}

-- Re-export utility function for backward compatibility.
M.has_unnecessary_whitespace = utils.has_unnecessary_whitespace

-- Scan a single file for whitespace issues.
--
-- @param path (string): file path.
-- @return table, boolean: quickfix entries and has_issue flag.
local function scan_single_file(path)
  local qf_entries = {}
  local has_issue = false

  -- Get lines from buffer or file (includes unsaved changes).
  local lines = utils.get_lines(path)

  if lines then
    for line_number, line in ipairs(lines) do
      if utils.has_unnecessary_whitespace(line) then
        table.insert(qf_entries, {
          filename = path,
          lnum = line_number,
          col = 1,
          text = line,
        })
        has_issue = true
      end
    end
  end

  return qf_entries, has_issue
end

-- Scan a list of files in batches.
-- Batching avoids long blocking loops when scanning
-- large repositories.
--
-- @param files (table): list of file paths.
-- @param batch_size (number): number of files per batch.
-- @return table, number: quickfix entries and affected file count.
local function scan_files(files, batch_size)
  local qf_entries = {}
  local files_with_issues = 0

  -- Iterate over file list in fixed-size batches.
  for i = 1, #files, batch_size do
    local end_idx = math.min(i + batch_size - 1, #files)

    for j = i, end_idx do
      local path = files[j]
      local entries, has_issue = scan_single_file(path)

      -- Add entries to quickfix list.
      for _, entry in ipairs(entries) do
        table.insert(qf_entries, entry)
      end

      if has_issue then
        files_with_issues = files_with_issues + 1
      end
    end
  end

  return qf_entries, files_with_issues
end

-- Public API
-- Entry point used by user commands.
-- @param files (table)
function M.run(files)
  return scan_files(files, 200)
end

return M
