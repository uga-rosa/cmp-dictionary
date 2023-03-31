local util = require("cmp_dictionary.util")
local Async = require("cmp_dictionary.kit.Async")
local lfu = require("cmp_dictionary.lfu")
local config = require("cmp_dictionary.config")
local utf8 = require("cmp_dictionary.lib.utf8")

local fn = vim.fn
local api = vim.api

---@class DictionaryData
---@field item lsp.CompletionItem
---@field mtime integer
---@field path string

local Caches = {
  ---@type DictionaryData[]
  valid = {},
}

local just_updated = false
local dictCache = lfu.init(config.get("capacity"))

---Create dictionary data from buffers
---@param path string
local create_cache = Async.async(function(path)
  local name = fn.fnamemodify(path, ":t")
  local buffer, stat = util.read_file_sync(path)
  local mtime = stat.mtime.sec

  local item = {}
  local detail = ("belong to `%s`"):format(name)
  for w in vim.gsplit(buffer, "%s+") do
    if w ~= "" then
      table.insert(item, { label = w, detail = detail })
    end
  end
  table.sort(item, function(item1, item2)
    return item1.label < item2.label
  end)

  local cache = {
    item = item,
    mtime = mtime,
    path = path,
  }

  dictCache:set(path, cache)
  table.insert(Caches.valid, cache)
end)

---@param path string
local function read_cache(path)
  if config.get("async") then
    create_cache(path)
  else
    create_cache(path):sync()
  end
end

---Filter to keep only dictionaries that have been updated or have not yet been cached.
---@return string[]
local function need_to_load()
  local dictionaries = util.get_dictionaries()
  local updated_or_new = {}
  for _, dict in ipairs(dictionaries) do
    local path = fn.expand(dict)
    if util.bool_fn.filereadable(path) then
      local mtime = fn.getftime(path)
      local cache = dictCache:get(path)
      if cache and cache.mtime == mtime then
        table.insert(Caches.valid, cache)
      else
        table.insert(updated_or_new, path)
      end
    end
  end
  return updated_or_new
end

local function update()
  local buftype = api.nvim_buf_get_option(0, "buftype")
  if buftype ~= "" then
    return
  end

  Caches.valid = {}

  local updated_or_new = need_to_load()
  if #updated_or_new == 0 then
    just_updated = true
    return
  end

  vim.tbl_map(read_cache, updated_or_new)
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

  local ok, offset, codepoint
  ok, offset = pcall(utf8.offset, req, -1)
  if not ok then
    return items, isIncomplete
  end
  ok, codepoint = pcall(utf8.codepoint, req, offset)
  if not ok then
    return items, isIncomplete
  end

  local req_next = req:sub(1, offset - 1) .. utf8.char(codepoint + 1)

  local max_items = config.get("max_items")
  for _, cache in pairs(Caches.valid) do
    local start = util.binary_search(cache.item, req, function(vector, index, key)
      return vector[index].label >= key
    end)
    local last = util.binary_search(cache.item, req_next, function(vector, index, key)
      return vector[index].label >= key
    end) - 1
    if start > 0 and last > 0 and start <= last then
      if max_items > 0 and last >= start + max_items then
        last = start + max_items
        isIncomplete = true
      end
      for i = start, last do
        local item = cache.item[i]
        table.insert(items, item)
      end
    end
  end
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
