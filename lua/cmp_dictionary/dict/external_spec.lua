local external = require("cmp_dictionary.dict.external")

local root = require("vusted.helper").find_plugin_root("cmp_dictionary")

describe("test for dict.external", function()
  vim.opt.runtimepath:append("../plenary.nvim")

  local dict = external.new({ "look", "${prefix}", "${path}" })
  dict:update({ root .. "/data/words" })

  it("search words", function()
    assert.same({
      { label = "bar", info = "belong to `words`" },
      { label = "baz", info = "belong to `words`" },
    }, dict:search("b"))
  end)
  it("search last word", function()
    assert.same({
      { label = "foo", info = "belong to `words`" },
    }, dict:search("f"))
  end)
end)
