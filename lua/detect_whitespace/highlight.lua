-- highlight.lua
-- Manages real-time highlighting of trailing whitespace in buffers.
-- Provides configuration for highlight groups and automatic highlighting.

local M = {}

-- Plugin configuration
local config = {
  highlight_group = "@text.note",  -- Default highlight group for trailing whitespace
  enable_highlight = true,          -- Enable/disable highlighting
}

-- Namespace for highlights
local ns_id = vim.api.nvim_create_namespace("detect_whitespace")

-- Highlight trailing whitespace in the current buffer
--
-- Uses the configured highlight group to mark trailing whitespace
function M.highlight_buffer()
  if not config.enable_highlight then
    return
  end

  local bufnr = vim.api.nvim_get_current_buf()
  
  -- Clear existing highlights
  vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)
  
  -- Get total lines in buffer
  local line_count = vim.api.nvim_buf_line_count(bufnr)
  
  -- Pattern for trailing whitespace (tab, space, full-width space)
  local pattern = "[\t 　]+$"
  
  -- Highlight each line with trailing whitespace
  for lnum = 0, line_count - 1 do
    local line = vim.api.nvim_buf_get_lines(bufnr, lnum, lnum + 1, false)[1]
    if line then
      local start_col, end_col = line:find(pattern)
      if start_col then
        vim.api.nvim_buf_add_highlight(
          bufnr,
          ns_id,
          config.highlight_group,
          lnum,
          start_col - 1,
          end_col
        )
      end
    end
  end
end

-- Clear all highlights in the current buffer
function M.clear_buffer()
  local bufnr = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)
end

-- Setup autocmd to highlight trailing whitespace
function M.setup_autocmd()
  local augroup = vim.api.nvim_create_augroup("DetectWhitespace", { clear = true })
  
  -- Highlight on buffer enter, text change, and insert leave
  vim.api.nvim_create_autocmd({ "BufEnter", "TextChanged", "TextChangedI", "InsertLeave" }, {
    group = augroup,
    callback = M.highlight_buffer,
  })
end

-- Configure the highlight module
--
-- @param opts table: Configuration options
--   - highlight_group (string): Highlight group to use (default: "@text.note")
--   - enable_highlight (boolean): Enable/disable highlighting (default: true)
function M.setup(opts)
  opts = opts or {}
  
  -- Update configuration
  if opts.highlight_group then
    config.highlight_group = opts.highlight_group
  end
  
  if opts.enable_highlight ~= nil then
    config.enable_highlight = opts.enable_highlight
  end
  
  -- Setup autocmd if highlighting is enabled
  if config.enable_highlight then
    M.setup_autocmd()
  end
end

-- Get current configuration
function M.get_config()
  return vim.deepcopy(config)
end

return M