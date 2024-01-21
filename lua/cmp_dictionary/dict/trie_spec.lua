local trie = require("cmp_dictionary.dict.trie")

local root = require("vusted.helper").find_plugin_root("cmp_dictionary")

local function assert_same_items(x, y)
  table.sort(x, function(a, b)
    return a.label < b.label
  end)
  table.sort(y, function(a, b)
    return a.label < b.label
  end)
  assert.same(x, y)
end

describe("test for dict.trie", function()
  local dict = trie.new()
  dict:update({ root .. "/data/words" })

  vim.wait(1000)

  it("search words", function()
    assert_same_items({
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
