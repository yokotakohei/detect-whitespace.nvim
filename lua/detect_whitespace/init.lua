-- init.lua
-- Entry point of the plugin.
-- This file defines user-facing Neovim commands and
-- connects them to internal implementation modules.

-- Import detection, fixing, and highlighting modules
local detect = require("detect_whitespace.detect")
local fix = require("detect_whitespace.fix")
local highlight = require("detect_whitespace.highlight")

-- Collect target files from a user-provided argument.
--
-- If no argument or "%" is given:
--   - operate on the current buffer only
-- Otherwise:
--   - expand the glob pattern into a list of files
--
-- @param pattern (string)
-- @return table: list of absolute file paths
local function collect_files(pattern)
  if pattern == "" or pattern == "%" then
    return { vim.fn.expand("%:p") }
  end

  local files = vim.fn.glob(pattern, false, true)

  -- Warn the user if the glob did not match anything
  if #files == 0 then
    vim.notify("No files found: " .. pattern, vim.log.levels.WARN)
  end

  return files
end

-- User command: DetectWhitespace
--
-- Scans files for unnecessary whitespace and reports
-- all findings via the quickfix list.
vim.api.nvim_create_user_command(
  "DetectWhitespace",
  function(opts)
    local files = collect_files(opts.args)
    if #files == 0 then return end

    -- Preserve current window and cursor position
    local win = vim.api.nvim_get_current_win()
    local cursor = vim.api.nvim_win_get_cursor(win)

    -- Run detection logic
    local qf_entries, affected_files = detect.run(files)

    -- Populate quickfix list
    vim.fn.setqflist(qf_entries)

    if #qf_entries > 0 then
      -- Open quickfix window but restore focus afterwards
      vim.cmd("copen")
      vim.api.nvim_set_current_win(win)
      vim.api.nvim_win_set_cursor(win, cursor)

      vim.notify(string.format(
        "Found %d issues in %d files (searched %d files)",
        #qf_entries,
        affected_files,
        #files
      ))
    else
      vim.notify("No unnecessary whitespace found")
    end
  end,
  { nargs = "?", complete = "file" }
)

-- User command: FixWhitespace
--
-- Removes unnecessary whitespace from files on disk.
-- Line count is preserved; only whitespace is normalized.
vim.api.nvim_create_user_command(
  "FixWhitespace",
  function(opts)
    local files = collect_files(opts.args)
    if #files == 0 then return end

    -- Apply fixes (handles both open buffers and files on disk)
    local fixed = fix.fix_files(files)
    vim.notify("Whitespace fixed in " .. fixed .. " files")
    
    -- Refresh highlights after fixing
    highlight.highlight_buffer()
  end,
  { nargs = "?", complete = "file" }
)

-- Public setup function for user configuration
--
-- @param opts table: Configuration options
--   - highlight_group (string): Highlight group to use (default: "@text.note")
--   - enable_highlight (boolean): Enable/disable highlighting (default: true)
local function setup(opts)
  highlight.setup(opts)
end

-- Initialize with default settings
setup()

-- Export setup function and highlight module
return {
  setup = setup,
  highlight = highlight,
}
