-- detect.lua
-- Implements read-only detection logic for unnecessary whitespace.
-- No file modifications are performed in this module.

local M = {}

-- Matches trailing whitespace at the end of a line
local TRAILING_PATTERN = "[\t 　]+$"

-- Matches lines consisting solely of whitespace characters
local BLANK_WITH_SPACE_PATTERN = "^[\t 　]+$"

-- Check if a line contains unnecessary whitespace
--
-- @param line (string): Line to check
-- @return boolean: true if the line has unnecessary whitespace
function M.has_unnecessary_whitespace(line)
  -- Check for trailing whitespace
  if line:match(TRAILING_PATTERN) then
    return true
  end

  -- Check for whitespace-only lines
  if line:match(BLANK_WITH_SPACE_PATTERN) then
    return true
  end

  return false
end

-- Scan a list of files in batches.
-- Batching avoids long blocking loops when scanning
-- large repositories.
--
-- @param files (table): list of file paths
-- @param batch_size (number): number of files per batch
-- @return table, number: quickfix entries and affected file count
local function scan_files(files, batch_size)
  local qf_entries = {}
  local files_with_issues = 0

  -- Iterate over file list in fixed-size batches
  for i = 1, #files, batch_size do
    local end_idx = math.min(i + batch_size - 1, #files)

    for j = i, end_idx do
      local path = files[j]
      local file = io.open(path, "r")

      -- Skip unreadable files silently
      if file then
        local line_number = 0
        local has_issue = false

        -- Read file line by line to minimize memory usage
        for line in file:lines() do
          line_number = line_number + 1

          -- Check for unnecessary whitespace
          if M.has_unnecessary_whitespace(line) then
            table.insert(qf_entries, {
              filename = path,
              lnum = line_number,
              col = 1,
              text = line,
            })
            has_issue = true
          end
        end

        if has_issue then
          files_with_issues = files_with_issues + 1
        end

        file:close()
      end
    end
  end

  return qf_entries, files_with_issues
end

-- Public API
-- Entry point used by user commands
-- @param files (table)
function M.run(files)
  return scan_files(files, 200)
end

return M
