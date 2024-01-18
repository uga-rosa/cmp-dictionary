local trie = require("cmp_dictionary.dict.trie")
local grep = require("cmp_dictionary.dict.grep")

local M = {}

---@class cmp.dictionary.dict
---@field update fun(self, paths: string[], force?: boolean)
---@field search fun(self, prefix: string): string[]

---@param opts cmp.dictionary.options
---@return cmp.dictionary.dict
function M.new(opts)
  if #opts.grep_command > 0 then
    return grep.new(opts.grep_command)
  else
    return trie.new()
  end
end

return M
