-- fix_spec.lua
-- Unit tests for fix module

local fix = require("detect_whitespace.fix")

describe("fix.normalize_line", function()

  -- Remove trailing whitespace
  it("removes trailing whitespace", function()
    assert.equals(
      "abc",
      fix.normalize_line("abc   ")
    )
  end)

  -- Remove trailing tabs
  it("removes trailing tabs", function()
    assert.equals(
      "abc",
      fix.normalize_line("abc\t\t")
    )
  end)

  -- Remove trailing full-width spaces
  it("removes trailing full-width spaces", function()
    assert.equals(
      "abc",
      fix.normalize_line("abc　　")
    )
  end)

  -- Remove mixed trailing whitespace
  it("removes mixed trailing whitespace", function()
    assert.equals(
      "abc",
      fix.normalize_line("abc \t　 ")
    )
  end)

  -- Convert whitespace-only line to empty line
  it("converts whitespace-only line to empty line", function()
    assert.equals(
      "",
      fix.normalize_line("   ")
    )
  end)

  -- Convert tab-only line to empty line
  it("converts tab-only line to empty line", function()
    assert.equals(
      "",
      fix.normalize_line("\t\t\t")
    )
  end)

  -- Convert mixed whitespace-only line to empty line
  it("converts mixed whitespace-only line to empty line", function()
    assert.equals(
      "",
      fix.normalize_line(" \t 　 \t")
    )
  end)

  -- Keep empty line unchanged
  it("keeps empty line unchanged", function()
    assert.equals(
      "",
      fix.normalize_line("")
    )
  end)

  -- Keep clean line unchanged
  it("keeps clean line unchanged", function()
    assert.equals(
      "abc",
      fix.normalize_line("abc")
    )
  end)

  -- Preserve whitespace within the line
  it("preserves whitespace within the line", function()
    assert.equals(
      "abc  def  ghi",
      fix.normalize_line("abc  def  ghi")
    )
  end)

  -- Preserve indentation
  it("preserves indentation", function()
    assert.equals(
      "  abc",
      fix.normalize_line("  abc")
    )
  end)

  -- Indentation + content + trailing whitespace
  it("removes trailing whitespace but preserves indentation", function()
    assert.equals(
      "  abc",
      fix.normalize_line("  abc  ")
    )
  end)

end)
