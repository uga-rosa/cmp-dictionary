local util = require("cmp_dictionary.util")
local Async = require("cmp_dictionary.kit.Async")
local lfu = require("cmp_dictionary.lfu")
local config = require("cmp_dictionary.config")

local fn = vim.fn
local api = vim.api
local uv = vim.loop

local items = {}

---@class DictionaryData
---@field item lsp.CompletionItem
---@field mtime integer
---@field path string

---@type DictionaryData[]
local dictionary_data = {}
local just_updated = false
local dictCache = lfu.init(config.get("capacity"))

---@param path string
---@return string
---@return table
local function read_file_sync(path)
  -- 292 == 0x444
  local fd = assert(uv.fs_open(path, "r", 292))
  local stat = assert(uv.fs_fstat(fd))
  local buffer = assert(uv.fs_read(fd, stat.size, 0))
  uv.fs_close(fd)
  return buffer, stat
end

---Create dictionary data from buffers
---@param path string
local create_cache = Async.async(function(path)
  local name = fn.fnamemodify(path, ":t")
  local buffer, stat = read_file_sync(path)
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
  table.insert(dictionary_data, cache)
end)

---@param path string
local function read_cache(path)
  if config.get("async") then
    if vim.mpack then
      create_cache(path)
    else
      vim.notify("[cmp-dictionary] The version of neovim is out of date.")
    end
  else
    create_cache(path):sync()
  end
end

---@return string[]
local function get_dictionaries()
  -- Workaround. vim.opt_global returns now a local value.
  -- https://github.com/neovim/neovim/issues/21506
  ---@type string[]
  local global = vim.split(vim.go.dictionary, ",")
  ---@type string[]
  local local_ = vim.opt_local.dictionary:get()

  local dict = {}
  for _, al in ipairs({ global, local_ }) do
    for _, d in ipairs(al) do
      if vim.fn.filereadable(vim.fn.expand(d)) == 1 then
        table.insert(dict, d)
      end
    end
  end
  return dict
end

---Filter to keep only dictionaries that have been updated or have not yet been cached.
---@param dictionaries string[]
---@return string[]
local function need_to_load(dictionaries)
  local updated_or_new = {}
  for _, dict in ipairs(dictionaries) do
    local path = fn.expand(dict)
    if util.bool_fn.filereadable(path) then
      local mtime = fn.getftime(path)
      local cache = dictCache:get(path)
      if cache and cache.mtime == mtime then
        table.insert(dictionary_data, cache)
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

  dictionary_data = {}
  local dict = get_dictionaries()

  local updated_or_new = need_to_load(dict)

  if #updated_or_new == 0 then
    just_updated = true
    return
  end

  vim.tbl_map(read_cache, updated_or_new)
end

function items.update()
  util.debounce(100, update)
end

---Get now candidates
---@return DictionaryData[]
function items.get()
  return dictionary_data
end

function items.is_just_updated()
  if just_updated then
    just_updated = false
    return true
  end
  return false
end

return items
