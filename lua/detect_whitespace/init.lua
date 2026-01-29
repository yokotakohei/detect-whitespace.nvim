-- init.lua
-- Entry point of the plugin.
-- This file defines user-facing Neovim commands and
-- connects them to internal implementation modules.


-- Import detection and fixing modules.
local detect = require("detect_whitespace.detect")
local fix = require("detect_whitespace.fix")
local highlight = require("detect_whitespace.highlight")

-- Module table for exported functions.
local M = {}

-- Setup function to configure the plugin.
--
-- @param opts (table|nil): configuration options.
--   - highlight_group: name of highlight group to use for highlighting.
--   - enable_on_setup: enable highlighting automatically for all buffers.
function M.setup(opts)
  highlight.setup(opts)
  
  -- Ensure commands are created after setup.
  _G._detect_whitespace_setup_done = true
end

-- Collect target files from a user-provided argument.
--
-- If no argument or "%" is given:
--   - operate on the current buffer only.
-- Otherwise:
--   - expand the glob pattern into a list of files.
--
-- @param pattern (string|table): glob pattern or list of patterns.
-- @return table: list of absolute file paths.
local function collect_files(pattern)
  -- Handle empty argument - use current buffer.
  if pattern == "" or pattern == "%" then
    return { vim.fn.expand("%:p") }
  end

  -- Convert string to table for uniform processing.
  local patterns = type(pattern) == "table" and pattern or { pattern }

  local all_files = {}
  local seen = {} -- Track duplicates.

  for _, pat in ipairs(patterns) do
    if pat ~= "" then
      -- Expand glob pattern.
      local files = vim.fn.glob(pat, false, true)

      -- Add unique files to the result (skip directories).
      for _, file in ipairs(files) do
        if not seen[file] then
          -- Skip directories.
          local stat = vim.loop.fs_stat(file)
          if stat and stat.type == "file" then
            seen[file] = true
            table.insert(all_files, file)
          end
        end
      end
    end
  end

  -- Warn the user if no files were found.
  if #all_files == 0 then
    local pattern_str = type(pattern) == "table" and table.concat(pattern, " ") or pattern
    vim.notify("No files found: " .. pattern_str, vim.log.levels.WARN)
  end

  return all_files
end

-- User command: DetectWhitespace.
--
-- Scans files for unnecessary whitespace and reports
-- all findings via the quickfix list.
vim.api.nvim_create_user_command(
  "DetectWhitespace",
  function(opts)
    -- Use fargs if provided, otherwise use current buffer.
    local pattern = #opts.fargs > 0 and opts.fargs or ""
    local files = collect_files(pattern)
    if #files == 0 then return end

    -- Preserve current window and cursor position.
    local win = vim.api.nvim_get_current_win()
    local cursor = vim.api.nvim_win_get_cursor(win)

    -- Run detection logic.
    local qf_entries, affected_files = detect.run(files)

    -- Populate quickfix list.
    vim.fn.setqflist(qf_entries)

    if #qf_entries > 0 then
      -- Open quickfix window but restore focus afterwards.
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
  { nargs = "*", complete = "file" }
)

-- User command: FixWhitespace.
--
-- Removes unnecessary whitespace from files on disk.
-- Line count is preserved; only whitespace is normalized.
vim.api.nvim_create_user_command(
  "FixWhitespace",
  function(opts)
    -- Use fargs if provided, otherwise use current buffer.
    local pattern = #opts.fargs > 0 and opts.fargs or ""
    local files = collect_files(pattern)
    if #files == 0 then return end

    -- Apply fixes (handles both open buffers and files on disk).
    local fixed = fix.fix_files(files)
    vim.notify("Whitespace fixed in " .. fixed .. " files")
  end,
  { nargs = "*", complete = "file" }
)

-- User command: HighlightWhitespace.
--
-- Enables real-time highlighting of unnecessary whitespace in current buffer.
vim.api.nvim_create_user_command(
  "HighlightWhitespace",
  function()
    highlight.enable_for_buffer()
    vim.notify("Whitespace highlighting enabled")
  end,
  {}
)

-- User command: HighlightWhitespaceDisable.
--
-- Disables whitespace highlighting in current buffer.
vim.api.nvim_create_user_command(
  "HighlightWhitespaceDisable",
  function()
    highlight.disable_for_buffer()
    vim.notify("Whitespace highlighting disabled")
  end,
  {}
)

-- User command: HighlightWhitespaceToggle.
--
-- Toggles whitespace highlighting in current buffer.
vim.api.nvim_create_user_command(
  "HighlightWhitespaceToggle",
  function()
    local bufnr = vim.api.nvim_get_current_buf()
    local augroup_name = "DetectWhitespace_" .. bufnr
    local exists = pcall(vim.api.nvim_get_autocmds, { group = augroup_name })

    if exists then
      highlight.disable_for_buffer()
      vim.notify("Whitespace highlighting disabled")
    else
      highlight.enable_for_buffer()
      vim.notify("Whitespace highlighting enabled")
    end
  end,
  {}
)

return M