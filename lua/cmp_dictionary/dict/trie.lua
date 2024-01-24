local Trie = require("cmp_dictionary.lib.trie")
local uv = vim.uv or vim.loop

---@class cmp.dictionary.dict.trie: cmp.dictionary.dict
---@field trie_map table<string, Trie>
---@field paths string[]
local M = {}

---@return cmp.dictionary.dict.trie
function M.new()
  return setmetatable({
    trie_map = {},
    paths = {},
  }, { __index = M })
end

---@param paths string[]
---@param force? boolean
function M:update(paths, force)
  if not force and vim.deep_equal(self.paths, paths) then
    return
  end
  self.paths = paths

  local work = uv.new_work(function(path)
    -- Can't reference upvalue because it's a separate thread.
    ---@diagnostic disable
    local Trie = require("cmp_dictionary.lib.trie")
    local uv = vim.uv or vim.loop

    local fd = assert(uv.fs_open(path, "r", 438))
    local stat = assert(uv.fs_fstat(fd))
    local data = assert(uv.fs_read(fd, stat.size, 0))
    assert(uv.fs_close(fd))

    local trie = Trie.new()
    for word in vim.gsplit(data, "\r?\n", { trimempty = true }) do
      trie:insert(word)
    end
    return path, vim.json.encode(trie)
    ---@diagnostic enable
  end, function(path, encoded_trie)
    local trie = vim.json.decode(encoded_trie) --[[@as Trie]]
    self.trie_map[path] = setmetatable(trie, { __index = Trie })
  end)

  for _, path in ipairs(paths) do
    if force or not self.trie_map[path] then
      work:queue(path)
    end
  end
end

---@param prefix string
---@return lsp.CompletionItem[]
function M:search(prefix)
  local items = {}
  for _, path in ipairs(self.paths) do
    local trie = self.trie_map[path]
    if not trie then
      -- The dictionary has not yet been loaded.
    else
      local info = string.format("belong to `%s`", vim.fn.fnamemodify(path, ":t"))
      for _, word in ipairs(trie:search(prefix)) do
        table.insert(items, { label = word, info = info })
      end
    end
  end
  return items
end

return M
