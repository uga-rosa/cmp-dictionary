---@alias dic_data {item: table, index: table}

---@class items
---@field cache LfuCache cached dictionary data (lfu)
---@field use_cache dic_data[] Currently dictionary data
local items = {}
items.just_updated = false

local fn = vim.fn
local api = vim.api
local uv = vim.loop

local lfu = require("cmp_dictionary.lfu")
local config = require("cmp_dictionary.config")

---@param ... unknown
local function log(...)
  if config.get("debug") then
    local msg = {}
    for _, v in ipairs({ ... }) do
      if type(v) == "table" then
        v = vim.inspect(v)
      end
      table.insert(msg, v)
    end
    print("[cmp-dictionary]", table.concat(msg, "\t"))
  end
end

-- cache
items.cache = lfu.init(config.get("capacity"))
items.use_cache = {}

local loading_count = 0
local function loaded()
  if loading_count > 0 then
    loading_count = loading_count - 1
  end
end

local function is_finished_loading()
  return loading_count == 0
end

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

---@class DictionaryData
---@field path string
---@field name string
---@field buffer string
---@field mtime integer

---Create dictionary data from buffers
---@param data DictionaryData
local function _create_cache(data, async)
  if async then
    data = vim.mpack.decode(data)
  end

  local item = {}
  local detail = "belong to `" .. data.name .. "`"
  for w in vim.gsplit(data.buffer, "%s+") do
    if w ~= "" then
      table.insert(item, { label = w, detail = detail })
    end
  end
  table.sort(item, function(item1, item2)
    return item1.label < item2.label
  end)

  local cache = { item = item, mtime = data.mtime, path = data.path }

  if async then
    return vim.mpack.encode(cache)
  end
  return cache
end

---@param data DictionaryData
local function create_cache_sync(data)
  local cache = _create_cache(data, false)
  items.cache:set(cache.path, cache)
  table.insert(items.use_cache, cache)
  log("Create cache: ", cache.path)
  loaded()
end

local create_cache_async = uv.new_work(_create_cache, function(cache)
  cache = vim.mpack.decode(cache)
  items.cache:set(cache.path, cache)
  table.insert(items.use_cache, cache)
  log("Create cache: ", cache.path)
  loaded()
end)

---@param path string
local function read_cache(path)
  local name = fn.fnamemodify(path, ":t")
  local buffer, stat = read_file_sync(path)
  log(("`%s` are loaded"):format(path))
  local data = {
    name = name,
    path = path,
    buffer = buffer,
    mtime = stat.mtime.sec,
  }

  if config.get("async") then
    if vim.mpack then
      log("Run asynchronously")
      create_cache_async:queue(vim.mpack.encode(data), true)
    else
      log("The version of neovim is out of date.")
    end
  else
    log("Run synchronously")
    create_cache_sync(data)
  end
end

---@param dictionaries string[]
---@return string[]
local function should_update(dictionaries)
  log("check to need to load >>>")
  local updated_or_new = {}
  for _, dic in ipairs(dictionaries) do
    local path = fn.expand(dic)
    if fn.filereadable(path) == 1 then
      local mtime = fn.getftime(path)
      local cache = items.cache:get(path)
      if cache and cache.mtime == mtime then
        table.insert(items.use_cache, cache)
        log("This file is cached: " .. path)
      else
        table.insert(updated_or_new, path)
        log("This file needs to be loaded: " .. path)
      end
    else
      log("No such file: " .. path)
    end
  end
  log("<<<")
  return updated_or_new
end

---@return string[]
local function get_dictionaries()
  -- Workaround. vim.opt_global returns now a local value.
  -- https://github.com/neovim/neovim/issues/21506
  ---@type string[]
  local global = vim.split(vim.go.dictionary, ",")
  ---@type string[]
  local local_ = vim.opt_local.dictionary:get()

  local dictionaries = {}
  for _, al in ipairs({ global, local_ }) do
    for _, dict in ipairs(al) do
      if vim.fn.filereadable(vim.fn.expand(dict)) == 1 then
        table.insert(dictionaries, dict)
      end
    end
  end
  return dictionaries
end

function items.update()
  if not is_finished_loading() then
    log("Now loading dictionaries. Please wait a while.")
    return
  end
  local buftype = api.nvim_buf_get_option(0, "buftype")
  if buftype ~= "" then
    return
  end

  items.use_cache = {}
  local dictionaries = get_dictionaries()

  log("Dictionaries for the current buffer:", dictionaries)

  local updated_or_new = should_update(dictionaries)

  if #updated_or_new == 0 then
    items.just_updated = true
    return
  end
  loading_count = #updated_or_new

  vim.tbl_map(read_cache, updated_or_new)
  log("All Dictionaries are loaded.")
end

---Get now candidates
---@return dic_data[]
function items.get()
  return items.use_cache
end

function items.is_just_updated()
  if items.just_updated then
    items.just_updated = false
    return true
  end
  return false
end

return items
