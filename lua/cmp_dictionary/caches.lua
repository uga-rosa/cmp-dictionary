local util = require("cmp_dictionary.util")
local lfu = require("cmp_dictionary.lfu")
local config = require("cmp_dictionary.config")
local Trie = require("cmp_dictionary.lib.trie")

---@class DictionaryData
---@field trie Trie
---@field mtime integer
---@field path string
---@field detail string

local Caches = {
  ---@type DictionaryData[]
  valid = {},
}

local just_updated = false
local dictCache = lfu.init(config.get("capacity"))

---Filter to keep only dictionaries that have been updated or have not yet been cached.
---@return {path: string, mtime: integer}[]
local function need_to_load()
  local dictionaries = util.get_dictionaries()
  local updated_or_new = {}
  for _, path in ipairs(dictionaries) do
    local mtime = vim.fn.getftime(path)
    local cache = dictCache:get(path)
    if cache and cache.mtime == mtime then
      table.insert(Caches.valid, cache)
    else
      table.insert(updated_or_new, { path = path, mtime = mtime })
    end
  end
  return updated_or_new
end

---@param path string
---@param mtime integer
local function cache_update(path, mtime)
  local buffer = util.read_file_sync(path)
  local trie = Trie.new()
  for w in vim.gsplit(buffer, "%s+") do
    if w ~= "" then
      trie:insert(w)
    end
  end

  local name = vim.fn.fnamemodify(path, ":t")
  local cache = {
    trie = trie,
    mtime = mtime,
    path = path,
    detail = ("belong to `%s`"):format(name),
  }

  dictCache:set(path, cache)
  table.insert(Caches.valid, cache)
end

local update_on_going = false
local function update()
  local buftype = vim.api.nvim_get_option_value("buftype", { buf = 0 })
  if buftype ~= "" or update_on_going then
    return
  end
  update_on_going = true

  Caches.valid = {}
  for _, n in ipairs(need_to_load()) do
    cache_update(n.path, n.mtime)
  end
  just_updated = true
  update_on_going = false
end

function Caches.update()
  util.debounce("update", update, 100)
end

---@param req string
---@param isIncomplete boolean
---@return lsp.CompletionItem[] items
---@return boolean isIncomplete
function Caches.request(req, isIncomplete)
  local items = {}
  isIncomplete = isIncomplete or false

  local max_items = config.get("max_items") --[[@as integer]]
  for _, cache in pairs(Caches.valid) do
    local words = cache.trie:search(req, max_items)
    for i = 1, #words do
      if max_items >= 0 and #items >= max_items then
        isIncomplete = true
        goto done
      end
      local item = { label = words[i], detail = cache.detail }
      table.insert(items, item)
    end
  end
  ::done::

  return items, isIncomplete
end

function Caches.is_just_updated()
  if just_updated then
    just_updated = false
    return true
  end
  return false
end

return Caches
