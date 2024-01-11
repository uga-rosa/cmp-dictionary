local trie = require("cmp_dictionary.dict.trie")

local M = {}

---@class CmpDictionaryDict
---@field update fun(self, paths: string[], force?: boolean)
---@field search fun(self, prefix: string): string[]

---@param opts CmpDictionaryOptions
---@return CmpDictionaryDict
function M.new(opts)
  return trie.new()
end

return M
