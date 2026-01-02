-- detect_spec.lua
-- Unit tests for detect module

local detect = require("detect_whitespace.detect")

describe("detect.has_unnecessary_whitespace", function()

  -- Detect trailing spaces
  it("detects trailing spaces", function()
    assert.is_true(
      detect.has_unnecessary_whitespace("abc   ")
    )
  end)

  -- Detect trailing tabs
  it("detects trailing tabs", function()
    assert.is_true(
      detect.has_unnecessary_whitespace("abc\t\t")
    )
  end)

  -- Detect trailing full-width spaces
  it("detects trailing full-width spaces", function()
    assert.is_true(
      detect.has_unnecessary_whitespace("abc　　")
    )
  end)

  -- Detect whitespace-only lines
  it("detects whitespace-only lines", function()
    assert.is_true(
      detect.has_unnecessary_whitespace("   ")
    )
  end)

  -- Detect tab-only lines
  it("detects tab-only lines", function()
    assert.is_true(
      detect.has_unnecessary_whitespace("\t\t\t")
    )
  end)

  -- Detect mixed whitespace-only lines
  it("detects mixed whitespace-only lines", function()
    assert.is_true(
      detect.has_unnecessary_whitespace(" \t 　 \t")
    )
  end)

  -- Correctly identify clean lines
  it("ignores clean lines", function()
    assert.is_false(
      detect.has_unnecessary_whitespace("abc")
    )
  end)

  -- Whitespace within the line is acceptable
  it("ignores whitespace within the line", function()
    assert.is_false(
      detect.has_unnecessary_whitespace("abc def ghi")
    )
  end)

  -- Empty lines are acceptable
  it("ignores empty lines", function()
    assert.is_false(
      detect.has_unnecessary_whitespace("")
    )
  end)

  -- Indented lines are acceptable
  it("ignores properly indented lines", function()
    assert.is_false(
      detect.has_unnecessary_whitespace("  abc")
    )
  end)

end)
