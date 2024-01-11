local Trie = require("cmp_dictionary.lib.trie")
local async = require("plenary.async")

---@class CmpDictionaryDictTrie: CmpDictionaryDict
---@field trie_map table<string, Trie>
---@field paths string[]
local M = {}

---@return CmpDictionaryDictTrie
function M.new()
  return setmetatable({
    trie_map = {},
    paths = {},
  }, { __index = M })
end

---@param x unknown
---@param y unknown
---@return boolean
local function same(x, y)
  return vim.json.encode(x) == vim.json.encode(y)
end

---@param path string
---@return string
local function read_file(path)
  ---@diagnostic disable: redefined-local
  -- luacheck: no redefined
  local err, fd = async.uv.fs_open(path, "r", tonumber("0666", 8))
  assert(not err, err)
  local err, stat = async.uv.fs_fstat(fd)
  assert(not err, err)
  local err, data = async.uv.fs_read(fd, stat.size, 0)
  assert(not err, err)
  local err = async.uv.fs_close(fd)
  assert(not err, err)
  ---@diagnostic enable
  return data
end

---@param paths string[]
---@param force? boolean
function M:update(paths, force)
  if not force and same(self.paths, paths) then
    return
  end
  self.paths = paths
  async.void(function()
    for _, path in ipairs(paths) do
      -- if force or not self.trie_map[path] then
      local trie = Trie.new()
      for word in vim.gsplit(read_file(path), "%s+", { trimempty = true }) do
        trie:insert(word)
      end
      self.trie_map[path] = trie
      -- end
    end
  end)()
end

---@param prefix string
function M:search(prefix)
  local items = {}
  for _, path in ipairs(self.paths) do
    local trie = self.trie_map[path]
    if trie then
      local info = string.format("belong to `%s`", vim.fn.fnamemodify(path, ":t"))
      items = vim.list_extend(
        items,
        vim.tbl_map(function(word)
          return { label = word, info = info }
        end, trie:search(prefix))
      )
    end
  end
  return items
end

return M
