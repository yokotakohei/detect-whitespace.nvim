-- utils_spec.lua
-- Unit tests for utils module.

local utils = require("detect_whitespace.utils")

describe("utils.has_unnecessary_whitespace", function()

  -- Detect trailing spaces.
  it("detects trailing spaces", function()
    assert.is_true(
      utils.has_unnecessary_whitespace("abc   ")
    )
  end)

  -- Detect trailing tabs.
  it("detects trailing tabs", function()
    assert.is_true(
      utils.has_unnecessary_whitespace("abc\t\t")
    )
  end)

  -- Detect trailing full-width spaces.
  it("detects trailing full-width spaces", function()
    assert.is_true(
      utils.has_unnecessary_whitespace("abc　　")
    )
  end)

  -- Detect whitespace-only lines.
  it("detects whitespace-only lines", function()
    assert.is_true(
      utils.has_unnecessary_whitespace("   ")
    )
  end)

  -- Detect tab-only lines.
  it("detects tab-only lines", function()
    assert.is_true(
      utils.has_unnecessary_whitespace("\t\t\t")
    )
  end)

  -- Detect mixed whitespace-only lines.
  it("detects mixed whitespace-only lines", function()
    assert.is_true(
      utils.has_unnecessary_whitespace(" \t 　 \t")
    )
  end)

  -- Correctly identify clean lines.
  it("ignores clean lines", function()
    assert.is_false(
      utils.has_unnecessary_whitespace("abc")
    )
  end)

  -- Whitespace within the line is acceptable.
  it("ignores whitespace within the line", function()
    assert.is_false(
      utils.has_unnecessary_whitespace("abc def ghi")
    )
  end)

  -- Empty lines are acceptable.
  it("ignores empty lines", function()
    assert.is_false(
      utils.has_unnecessary_whitespace("")
    )
  end)

  -- Indented lines are acceptable.
  it("ignores properly indented lines", function()
    assert.is_false(
      utils.has_unnecessary_whitespace("  abc")
    )
  end)

end)

describe("utils.find_whitespace_positions", function()

  -- Find trailing spaces.
  it("finds trailing spaces", function()
    local positions = utils.find_whitespace_positions("abc   ")
    assert.equals(1, #positions)
    assert.equals(4, positions[1].start_col)
    assert.equals(6, positions[1].end_col)
  end)

  -- Find trailing tabs.
  it("finds trailing tabs", function()
    local positions = utils.find_whitespace_positions("abc\t\t")
    assert.equals(1, #positions)
    assert.equals(4, positions[1].start_col)
    assert.equals(5, positions[1].end_col)
  end)

  -- Find whitespace-only line.
  it("finds whitespace-only line", function()
    local positions = utils.find_whitespace_positions("   ")
    assert.equals(1, #positions)
    assert.equals(1, positions[1].start_col)
    assert.equals(3, positions[1].end_col)
  end)

  -- No positions for clean line.
  it("returns empty table for clean line", function()
    local positions = utils.find_whitespace_positions("abc")
    assert.equals(0, #positions)
  end)

  -- No positions for empty line.
  it("returns empty table for empty line", function()
    local positions = utils.find_whitespace_positions("")
    assert.equals(0, #positions)
  end)

  -- No positions for properly indented line.
  it("returns empty table for properly indented line", function()
    local positions = utils.find_whitespace_positions("  abc")
    assert.equals(0, #positions)
  end)

  -- Avoid duplicates (trailing whitespace that is also whitespace-only).
  it("avoids duplicate positions", function()
    local positions = utils.find_whitespace_positions("  \t")
    -- Should only have one position, not two.
    assert.equals(1, #positions)
  end)

end)

describe("utils.normalize_line", function()

  -- Remove trailing whitespace.
  it("removes trailing whitespace", function()
    assert.equals(
      "abc",
      utils.normalize_line("abc   ")
    )
  end)

  -- Remove trailing tabs.
  it("removes trailing tabs", function()
    assert.equals(
      "abc",
      utils.normalize_line("abc\t\t")
    )
  end)

  -- Remove trailing full-width spaces.
  it("removes trailing full-width spaces", function()
    assert.equals(
      "abc",
      utils.normalize_line("abc　　")
    )
  end)

  -- Remove mixed trailing whitespace.
  it("removes mixed trailing whitespace", function()
    assert.equals(
      "abc",
      utils.normalize_line("abc \t　 ")
    )
  end)

  -- Convert whitespace-only line to empty line.
  it("converts whitespace-only line to empty line", function()
    assert.equals(
      "",
      utils.normalize_line("   ")
    )
  end)

  -- Convert tab-only line to empty line.
  it("converts tab-only line to empty line", function()
    assert.equals(
      "",
      utils.normalize_line("\t\t\t")
    )
  end)

  -- Convert mixed whitespace-only line to empty line.
  it("converts mixed whitespace-only line to empty line", function()
    assert.equals(
      "",
      utils.normalize_line(" \t 　 \t")
    )
  end)

  -- Keep empty line unchanged.
  it("keeps empty line unchanged", function()
    assert.equals(
      "",
      utils.normalize_line("")
    )
  end)

  -- Keep clean line unchanged.
  it("keeps clean line unchanged", function()
    assert.equals(
      "abc",
      utils.normalize_line("abc")
    )
  end)

  -- Preserve whitespace within the line.
  it("preserves whitespace within the line", function()
    assert.equals(
      "abc  def  ghi",
      utils.normalize_line("abc  def  ghi")
    )
  end)

  -- Preserve indentation.
  it("preserves indentation", function()
    assert.equals(
      "  abc",
      utils.normalize_line("  abc")
    )
  end)

  -- Indentation + content + trailing whitespace.
  it("removes trailing whitespace but preserves indentation", function()
    assert.equals(
      "  abc",
      utils.normalize_line("  abc  ")
    )
  end)

end)

describe("utils.get_file_lines", function()

  -- Read a file successfully.
  it("reads a file successfully", function()
    -- Create a temporary test file.
    local test_file = os.tmpname()
    local f = io.open(test_file, "w")
    f:write("line1\n")
    f:write("line2\n")
    f:write("line3\n")
    f:close()

    local lines = utils.get_file_lines(test_file)
    assert.is_not_nil(lines)
    assert.equals(3, #lines)
    assert.equals("line1", lines[1])
    assert.equals("line2", lines[2])
    assert.equals("line3", lines[3])

    -- Clean up.
    os.remove(test_file)
  end)

  -- Return nil for non-existent file.
  it("returns nil for non-existent file", function()
    local lines = utils.get_file_lines("/non/existent/file.txt")
    assert.is_nil(lines)
  end)

  -- Handle empty file.
  it("handles empty file", function()
    local test_file = os.tmpname()
    local f = io.open(test_file, "w")
    f:close()

    local lines = utils.get_file_lines(test_file)
    assert.is_not_nil(lines)
    assert.equals(0, #lines)

    -- Clean up.
    os.remove(test_file)
  end)

end)

describe("utils.is_directory", function()

  -- Detect directory.
  it("detects directory", function()
    -- Current directory should be a directory.
    assert.is_true(utils.is_directory("."))
  end)

  -- Detect file is not directory.
  it("detects file is not directory", function()
    -- Create a temporary test file.
    local test_file = os.tmpname()
    local f = io.open(test_file, "w")
    f:close()

    assert.is_false(utils.is_directory(test_file))

    -- Clean up.
    os.remove(test_file)
  end)

  -- Return false for non-existent path.
  it("returns false for non-existent path", function()
    assert.is_false(utils.is_directory("/non/existent/path"))
  end)

end)
