local util = require("cmp_dictionary.util")

---@class CmpDictionaryDictGrep: CmpDictionaryDict
---@field command string[]
---@field paths string[]
local M = {}

---@param command string[]
---@return CmpDictionaryDictGrep
function M.new(command)
  return setmetatable({
    command = command,
    paths = {},
  }, { __index = M })
end

---@param paths string[]
function M:update(paths)
  self.paths = paths
end

---@param prefix string
function M:search(prefix)
  local items = {}
  for _, path in ipairs(self.paths) do
    local command = vim.tbl_map(function(c)
      return c:gsub("${prefix}", prefix):gsub("${path}", path)
    end, self.command)
    local info = string.format("belong to `%s`", vim.fn.fnamemodify(path, ":t"))
    items = vim.list_extend(
      items,
      vim.tbl_map(function(word)
        return { label = word, info = info }
      end, vim.split(util.system(command), "\n"))
    )
  end
  return items
end

return M
