local lfu = require("cmp_dictionary.lfu")

local cache

describe("Test for lfu.lua", function()
  before_each(function()
    cache = lfu.init(5)
  end)

  it("single cache", function()
    cache:set("a", 1)
    assert.is.equal(1, cache:get("a"))
  end)
end)
