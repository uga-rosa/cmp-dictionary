local u = require("cmp_dictionary.lib.unknown")
local is = u.is

describe("Test for lib/unknown", function()
  it("is.Nil", function()
    assert.equal(true, is.Nil(nil))
    assert.equal(false, is.Nil(false))
  end)
  it("is.Boolean", function()
    assert.equal(true, is.Boolean(true))
    assert.equal(false, is.Boolean("x"))
  end)
  it("is.String", function()
    assert.equal(true, is.String("x"))
    assert.equal(false, is.String(1))
  end)
  it("is.Number", function()
    assert.equal(true, is.Number(1))
    assert.equal(false, is.Number("x"))
  end)
  it("is.Function", function()
    assert.equal(true, is.Function(function() end))
    assert.equal(false, is.Function({}))
  end)
  it("is.Table", function()
    assert.equal(true, is.Table({ 1, 2 }))
    assert.equal(false, is.Table(false))
  end)
  it("is.Thread", function()
    assert.equal(true, is.Thread(coroutine.create(function() end)))
    assert.equal(false, is.Thread("x"))
  end)
  it("is.Userdata", function()
    assert.equal(true, is.Userdata(newproxy(true)))
    assert.equal(false, is.Userdata(false))
  end)
  describe("is.TableOf", function()
    it("loose", function()
      local pred1 = is.TableOf({ a = is.String })
      local pred2 = is.TableOf({ b = is.Number, c = is.Boolean })
      assert.equal(true, pred1({ a = "x", b = "y" }))
      assert.equal(true, pred2({ a = "x", b = 1, c = true }))
      assert.equal(false, pred1({ a = 1 }))
      assert.equal(false, pred2({ b = "x", c = true }))
    end)
    it("strict", function()
      local pred1 = is.TableOf({ a = is.List }, { strict = true })
      local pred2 = is.TableOf({ b = is.Function, c = is.Table }, { strict = true })
      assert.equal(true, pred1({ a = { 1, 2 } }))
      assert.equal(true, pred2({ b = function() end, c = { a = "x" } }))
      assert.equal(false, pred1({ a = { b = "x" } }))
      assert.equal(false, pred2({ b = function() end, c = { 1 }, d = "x" }))
    end)
    it("nested", function()
      assert.equal(true, is.TableOf({ a = is.TableOf({ b = is.String }) })({ a = { b = "x" } }))
      assert.equal(false, is.TableOf({ a = is.TableOf({ b = is.String }) })({ a = { b = 1 } }))
    end)
  end)
  it("is.List", function()
    assert.equal(true, is.List({ 1, 2 }))
    assert.equal(false, is.List({ a = "a" }))
  end)
  it("is.ListOf", function()
    assert.equal(true, is.ListOf(is.String)({ "a", "b", "c" }))
    assert.equal(false, is.ListOf(is.Number)({ "a", "b", "c" }))
  end)
  it("is.OptionalOf", function()
    assert.equal(true, is.OptionalOf(is.String)("x"))
    assert.equal(true, is.OptionalOf(is.String)(nil))
    assert.equal(false, is.OptionalOf(is.Number)("x"))
  end)
  it("is.OneOf", function()
    assert.equal(true, is.OneOf({ is.String, is.Number })("x"))
    assert.equal(true, is.OneOf({ is.String, is.Number })(1))
    assert.equal(false, is.OneOf({ is.String, is.Number })(true))
  end)

  it("assert", function()
    local ok = pcall(u.assert, "x", is.String)
    assert.equal(true, ok)
    ok = pcall(u.assert, "x", is.Number)
    assert.equal(false, ok)
  end)
  it("ensure", function()
    local x = u.ensure("x", is.String)
    assert.equal(x, "x")
    local ok = pcall(u.ensure, "x", is.Number)
    assert.equal(false, ok)
  end)
  it("maybe", function()
    local x = u.maybe("x", is.String)
    assert.equal("x", x)
    local y = u.maybe("y", is.Number)
    assert.equal(nil, y)
  end)
end)
