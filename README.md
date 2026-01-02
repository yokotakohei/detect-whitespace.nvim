# detect-whitespace.nvim

[![Test](https://github.com/yokotakohei/detect-whitespace.nvim/actions/workflows/test.yml/badge.svg)](https://github.com/yokotakohei/detect-whitespace.nvim/actions/workflows/test.yml)

A Neovim plugin to detect and remove unnecessary whitespace.

## Features

- **Whitespace Detection**: Detects unnecessary whitespace in files and displays them in the quickfix list
- **Whitespace Removal**: Automatically removes unnecessary whitespace
- **Batch Processing**: Process multiple files at once

## Types of Whitespace Detected

1. **Trailing whitespace**
   - Regular spaces, tabs, and full-width spaces

2. **Whitespace-only lines**
   - Convert lines containing only whitespace to empty lines

## Installation

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  'yokotakohei/detect-whitespace.nvim',
  config = function()
    -- Load the plugin
    require('detect_whitespace')
  end,
}
```

## Usage

### Commands

#### `:DetectWhitespace [pattern]`

Detects unnecessary whitespace in files and displays them in the quickfix list.

```vim
" Check current buffer
:DetectWhitespace

" Check current buffer (explicit)
:DetectWhitespace %

" Check specific file
:DetectWhitespace path/to/file.txt

" Check multiple files with glob pattern
:DetectWhitespace src/**/*.lua
:DetectWhitespace *.py
```

#### `:FixWhitespace [pattern]`

Removes unnecessary whitespace. Files are modified directly.

```vim
" Fix whitespace in current buffer
:FixWhitespace

" Fix whitespace in specific file
:FixWhitespace path/to/file.txt

" Fix whitespace in multiple files
:FixWhitespace src/**/*.lua
:FixWhitespace *.py
```

### Lua API

You can also use the plugin's functionality directly from Lua.

```lua
local detect = require('detect_whitespace.detect')
local fix = require('detect_whitespace.fix')

-- Check if a line has unnecessary whitespace
local has_issue = detect.has_unnecessary_whitespace("example line  ")  -- true
local is_clean = detect.has_unnecessary_whitespace("clean line")      -- false

-- Normalize whitespace in a line
local normalized = fix.normalize_line("example  \t ")  -- "example"
local empty = fix.normalize_line("  \t  ")            -- ""

-- Fix a single file
local modified = fix.fix_file("/path/to/file.txt")  -- returns true if modified

-- Fix multiple files
local files = { "file1.txt", "file2.txt", "file3.txt" }
local count = fix.fix_files(files)  -- returns number of modified files
```

## Development

### Running Tests

This project uses [plenary.nvim](https://github.com/nvim-lua/plenary.nvim) for testing.

```bash
# Install plenary.nvim
git clone https://github.com/nvim-lua/plenary.nvim \
  ~/.local/share/nvim/site/pack/vendor/start/plenary.nvim

# Run tests
nvim --headless -c "PlenaryBustedDirectory tests/ { minimal_init = 'tests/minimal_init.vim' }"
```

### CI/CD

This project uses GitHub Actions for automated testing. Tests run automatically on pull requests and pushes to the main branch.

Workflow file: [`.github/workflows/test.yml`](.github/workflows/test.yml)

### Project Structure

```
detect-whitespace.nvim/
├── lua/
│   └── detect_whitespace/
│       ├── init.lua     # Plugin entry point
│       ├── detect.lua   # Whitespace detection logic
│       └── fix.lua      # Whitespace fixing logic
├── tests/
│   ├── detect_spec.lua  # Tests for detect.lua
│   ├── fix_spec.lua     # Tests for fix.lua
│   └── minimal_init.vim # Minimal config for tests
├── .github/
│   └── workflows/
│       └── test.yml     # GitHub Actions config
└── README.md            # This file
```

## License

MIT License

## Contributing

Pull requests and issue reports are welcome!

1. Fork this repository
2. Create a new branch
3. Implement your changes
4. Add and run tests
5. Create a pull request