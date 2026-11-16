-- fix_spec.lua
-- Unit tests for fix module.

local fix = require("detect_whitespace.fix")

describe("fix.normalize_line", function()

  -- Remove trailing whitespace.
  it("removes trailing whitespace", function()
    assert.equals(
      "abc",
      fix.normalize_line("abc   ")
    )
  end)

  -- Remove trailing tabs.
  it("removes trailing tabs", function()
    assert.equals(
      "abc",
      fix.normalize_line("abc\t\t")
    )
  end)

  -- Remove trailing full-width spaces.
  it("removes trailing full-width spaces", function()
    assert.equals(
      "abc",
      fix.normalize_line("abc　　")
    )
  end)

  -- Remove mixed trailing whitespace.
  it("removes mixed trailing whitespace", function()
    assert.equals(
      "abc",
      fix.normalize_line("abc \t　 ")
    )
  end)

  -- Convert whitespace-only line to empty line.
  it("converts whitespace-only line to empty line", function()
    assert.equals(
      "",
      fix.normalize_line("   ")
    )
  end)

  -- Convert tab-only line to empty line.
  it("converts tab-only line to empty line", function()
    assert.equals(
      "",
      fix.normalize_line("\t\t\t")
    )
  end)

  -- Convert mixed whitespace-only line to empty line.
  it("converts mixed whitespace-only line to empty line", function()
    assert.equals(
      "",
      fix.normalize_line(" \t 　 \t")
    )
  end)

  -- Keep empty line unchanged.
  it("keeps empty line unchanged", function()
    assert.equals(
      "",
      fix.normalize_line("")
    )
  end)

  -- Keep clean line unchanged.
  it("keeps clean line unchanged", function()
    assert.equals(
      "abc",
      fix.normalize_line("abc")
    )
  end)

  -- Preserve whitespace within the line.
  it("preserves whitespace within the line", function()
    assert.equals(
      "abc  def  ghi",
      fix.normalize_line("abc  def  ghi")
    )
  end)

  -- Preserve indentation.
  it("preserves indentation", function()
    assert.equals(
      "  abc",
      fix.normalize_line("  abc")
    )
  end)

  -- Indentation + content + trailing whitespace.
  it("removes trailing whitespace but preserves indentation", function()
    assert.equals(
      "  abc",
      fix.normalize_line("  abc  ")
    )
  end)

end)


describe("fix.fix_file", function()

  local function write_bytes(content)
    local path = os.tmpname()
    local f = io.open(path, "wb")
    f:write(content)
    f:close()
    return path
  end

  local function read_bytes(path)
    local f = io.open(path, "rb")
    local content = f:read("*a")
    f:close()
    return content
  end

  -- Run fix_file and return the resulting bytes.
  local function fix_bytes(content)
    local path = write_bytes(content)
    local modified = fix.fix_file(path)
    local result = read_bytes(path)
    os.remove(path)
    return result, modified
  end

  it("keeps LF line endings", function()
    local result, modified = fix_bytes("a  \nb\n")
    assert.is_true(modified)
    assert.equals("a\nb\n", result)
  end)

  -- Regression: text-mode writes on Windows turned LF files into CRLF.
  it("does not add CR to LF files", function()
    local result = fix_bytes("a \nb \nc\n")
    assert.is_nil(result:find("\r", 1, true))
  end)

  it("keeps CRLF line endings and removes whitespace before them", function()
    local result, modified = fix_bytes("a  \r\n   \r\nb\r\n")
    assert.is_true(modified)
    assert.equals("a\r\n\r\nb\r\n", result)
  end)

  it("keeps mixed line endings", function()
    local result = fix_bytes("a \r\nb \nc\r\n")
    assert.equals("a\r\nb\nc\r\n", result)
  end)

  it("does not add a newline to a last line without one", function()
    local result = fix_bytes("a\nb  ")
    assert.equals("a\nb", result)
  end)

  it("keeps multibyte characters intact", function()
    local result = fix_bytes("! フォルダ\n! 値、　\r\n倀\t\n")
    assert.equals("! フォルダ\n! 値、\r\n倀\n", result)
  end)

  it("does not rewrite a clean file", function()
    local content = "a\r\nフォルダ\nb"
    local result, modified = fix_bytes(content)
    assert.is_false(modified)
    assert.equals(content, result)
  end)

end)

describe("fix.fix_buffer", function()

  it("keeps a CR at the end of buffer lines", function()
    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "a  \r", "フォルダ" })
    assert.is_true(fix.fix_buffer(bufnr))
    assert.same({ "a\r", "フォルダ" }, vim.api.nvim_buf_get_lines(bufnr, 0, -1, false))
    vim.api.nvim_buf_delete(bufnr, { force = true })
  end)

end)
