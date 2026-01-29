-- highlight.lua
-- Implements real-time highlighting of unnecessary whitespace

local utils = require("detect_whitespace.utils")

local M = {}

-- Default configuration
M.config = {
  -- Highlight group to use (defaults to link to Todo)
  highlight_group = "DetectWhitespace",
  -- Enable highlighting by default (set to false to disable)
  enable_on_setup = false,
}

-- Namespace for our highlights
local ns_id = vim.api.nvim_create_namespace("detect_whitespace")

-- Setup function to configure the plugin
--
-- @param opts (table|nil): configuration options
--   - highlight_group: name of highlight group to use
--   - enable_on_setup: enable highlighting automatically for all buffers
function M.setup(opts)
  opts = opts or {}
  M.config = vim.tbl_extend("force", M.config, opts)

  -- Create default highlight group linked to Todo
  vim.api.nvim_set_hl(0, "DetectWhitespace", { link = "Todo", default = true })

  -- Enable highlighting for all buffers if requested
  if M.config.enable_on_setup then
    vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
      group = vim.api.nvim_create_augroup("DetectWhitespaceAutoEnable", { clear = true }),
      callback = function(args)
        M.enable_for_buffer(args.buf)
      end,
    })
  end
end

-- Highlight unnecessary whitespace in a buffer
--
-- @param bufnr (number): buffer number to highlight
function M.highlight_buffer(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  -- Clear existing highlights
  vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)

  local lines = utils.get_buffer_lines(bufnr)

  for lnum, line in ipairs(lines) do
    -- Find all whitespace positions in the line
    local positions = utils.find_whitespace_positions(line)

    -- Highlight each position
    for _, pos in ipairs(positions) do
      vim.api.nvim_buf_add_highlight(
        bufnr,
        ns_id,
        M.config.highlight_group,
        lnum - 1, -- 0-indexed
        pos.start_col - 1, -- 0-indexed
        pos.end_col
      )
    end
  end
end

-- Clear highlights from a buffer
--
-- @param bufnr (number): buffer number
function M.clear_buffer(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)
end

-- Enable automatic highlighting for a buffer
--
-- @param bufnr (number): buffer number
function M.enable_for_buffer(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  -- Initial highlight
  M.highlight_buffer(bufnr)

  -- Setup autocmds for this buffer
  local augroup = vim.api.nvim_create_augroup("DetectWhitespace_" .. bufnr, { clear = true })

  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "InsertLeave" }, {
    group = augroup,
    buffer = bufnr,
    callback = function()
      M.highlight_buffer(bufnr)
    end,
  })

  -- Clean up when buffer is deleted
  vim.api.nvim_create_autocmd("BufDelete", {
    group = augroup,
    buffer = bufnr,
    callback = function()
      vim.api.nvim_del_augroup_by_id(augroup)
    end,
  })
end

-- Disable automatic highlighting for a buffer
--
-- @param bufnr (number): buffer number
function M.disable_for_buffer(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  -- Clear highlights
  M.clear_buffer(bufnr)

  -- Remove autocmds
  local ok, _ = pcall(vim.api.nvim_del_augroup_by_name, "DetectWhitespace_" .. bufnr)
  if not ok then
    -- Augroup doesn't exist, that's fine
  end
end

return M
