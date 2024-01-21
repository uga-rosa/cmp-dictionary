local config = require("cmp_dictionary.config")
local trie = require("cmp_dictionary.dict.trie")
local external = require("cmp_dictionary.dict.external")

local M = {}

---@class cmp.dictionary.dict
---@field update fun(self: cmp.dictionary.dict, paths: string[], force?: boolean)
---@field search fun(self: cmp.dictionary.dict, prefix: string): lsp.CompletionItem[]

---@return cmp.dictionary.dict
function M.new()
  local opts = config.options
  if opts.external.enable then
    return external.new(opts.external.command)
  else
    return trie.new()
  end
end

return M
