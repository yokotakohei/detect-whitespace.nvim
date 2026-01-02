-- Minimal initialization for test execution

-- Add plenary.nvim to runtimepath
vim.cmd([[
  set runtimepath+=~/.local/share/nvim/site/pack/vendor/start/plenary.nvim
  set runtimepath+=~/.local/share/nvim/site/pack/vendor/start/detect-whitespace.nvim
  set runtimepath+=.
]])