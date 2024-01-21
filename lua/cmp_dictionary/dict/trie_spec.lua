local trie = require("cmp_dictionary.dict.trie")

local root = require("vusted.helper").find_plugin_root("cmp_dictionary")

describe("test for dict.external", function()
  local dict = trie.new()
  dict:update({ vim.fs.joinpath(root, "data", "words") })

  vim.wait(1000)

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
