local Trie = require("cmp_dictionary.lib.trie")

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

---@param paths string[]
---@param force? boolean
function M:update(paths, force)
  if not force and same(self.paths, paths) then
    return
  end
  self.paths = paths
  for _, path in ipairs(paths) do
    if force or not self.trie_map[path] then
      vim.uv
        .new_work(function(path)
          local fd = assert(vim.uv.fs_open(path, "r", 438))
          local stat = assert(vim.uv.fs_fstat(fd))
          local data = assert(vim.uv.fs_read(fd, stat.size, 0))
          assert(vim.uv.fs_close(fd))

          local Trie = require("cmp_dictionary.lib.trie")
          local trie = Trie.new()
          for word in vim.gsplit(data, "%s+", { trimempty = true }) do
            trie:insert(word)
          end
          return vim.json.encode(trie)
        end, function(json_str)
          local trie = setmetatable(vim.json.decode(json_str), { __index = Trie })
          self.trie_map[path] = trie
        end)
        :queue(path)
    end
  end
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
