local trie = require("cmp_dictionary.dict.trie")
local external = require("cmp_dictionary.dict.external")

local M = {}

---@class cmp.dictionary.dict
---@field update fun(self, paths: string[], force?: boolean)
---@field search fun(self, prefix: string): string[]

---@param opts cmp.dictionary.options
---@return cmp.dictionary.dict
function M.new(opts)
  if opts.external.enable then
    return external.new(opts.external.command)
  else
    return trie.new()
  end
end

return M
