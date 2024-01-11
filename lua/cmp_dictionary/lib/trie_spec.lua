local Trie = require("cmp_dictionary.lib.trie")

local function set(list)
  local s = {}
  for _, l in ipairs(list) do
    s[l] = true
  end
  return s
end

local function assert_same_set(x, y)
  assert.same(set(x), set(y))
end

it("Test for lib/trie", function()
  local trie = Trie.new()

  trie:insert("foo")
  trie:insert("foo1")
  trie:insert("foo2")
  trie:insert("bar")

  assert_same_set({ "foo", "foo1", "foo2" }, trie:search("foo"))
end)
