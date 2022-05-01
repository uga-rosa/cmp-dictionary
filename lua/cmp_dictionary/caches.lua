---@alias dic_data {item: table, index: table}

---@class items
---@field cache LfuCache cached dictionary data (lfu)
---@field use_cache dic_data[] Currently dictionary data
local items = {}
items.post = {}

local fn = vim.fn
local api = vim.api
local uv = vim.loop
local lfu = require("cmp_dictionary.lfu")
local config = require("cmp_dictionary.config")

local function log(...)
    if config.get("debug") then
        local msg = {}
        for _, v in ipairs({...}) do
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

---Create dictionary data from buffers
---@param buffers {path: string, name: string, buffer: string}[]
local function _create_cache(buffers, async)
    local new_caches = {}

    if async then
        buffers = require("mpack").Unpacker()(buffers)
    end

    for _, buf in ipairs(buffers) do
        local item = {}
        local detail = "belong to `" .. buf.name .. "`"
        for w in vim.gsplit(buf.buffer, "%s+") do
            if w ~= "" then
                table.insert(item, { label = w, detail = detail })
            end
        end
        table.sort(item, function(item1, item2)
            return item1.label < item2.label
        end)

        new_caches[buf.path] = { item = item, mtime = buf.mtime }
    end

    if async then
        return require("mpack").Packer()(new_caches)
    end
    return new_caches
end

function items.create_cache_sync(buffers)
    local paths = {}
    for path, cache in pairs(_create_cache(buffers, false)) do
        items.cache:set(path, cache)
        table.insert(items.use_cache, cache)
        table.insert(paths, path)
    end
    log("All dictionary loaded", paths)
end

items.create_cache_async = uv.new_work(_create_cache, function(_cache)
    local paths = {}
    for path, cache in pairs(vim.mpack.decode(_cache)) do
        items.cache:set(path, cache)
        table.insert(items.use_cache, cache)
        table.insert(paths, path)
    end
    log("All dictionary loaded", paths)
end)

function items.should_update(dictionaries)
    log("check to need to load >>>")
    if type(dictionaries) ~= "table" then
        dictionaries = { dictionaries }
    end
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

function items.update()
    local buftype = api.nvim_buf_get_option(0, "buftype")
    if buftype ~= "" then
        return
    end

    if not config.ready then
        log("Setup has NOT been called.")
        return
    end

    items.use_cache = {}
    local dictionaries

    local dic = config.get("dic")
    if dic.filename then
        local filename = vim.fn.expand("%:t")
        dictionaries = dic.filename[filename]
    end
    if dic.filepath and not dictionaries then
        local filepath = vim.fn.expand("%:p")
        for path, dict in pairs(dic.filepath) do
            if filepath:find(path) then
                dictionaries = dict
            end
        end
    end
    if not dictionaries then
        dictionaries = dic[vim.bo.filetype] or dic["*"]
    end

    log("Dictionaries for the current buffer:", dictionaries)

    local updated_or_new = items.should_update(dictionaries)
    if #updated_or_new == 0 then
        return
    end

    local buffers = {}

    for _, path in ipairs(updated_or_new) do
        local name = fn.fnamemodify(path, ":t")

        uv.fs_open(path, "r", 438, function(err, fd)
            assert(not err, err)
            uv.fs_fstat(fd, function(err2, stat)
                assert(not err2, err2)
                uv.fs_read(fd, stat.size, 0, function(err3, buffer)
                    assert(not err3, err3)
                    uv.fs_close(fd, function(err4)
                        assert(not err4, err4)
                        table.insert(buffers, { buffer = buffer, path = path, name = name, mtime = stat.mtime.sec })
                        log(("`%s` are loaded"):format(path))
                    end)
                end)
            end)
        end)
    end

    local timer = uv.new_timer()
    timer:start(0, 100, function()
        if #buffers == #updated_or_new then
            timer:stop()
            timer:close()
            if config.get("async") then
                if vim.mpack then
                    log("Run asynchronously")
                    items.create_cache_async:queue(vim.mpack.encode(buffers), true)
                    return
                else
                    log("Module `mpack` is not available")
                end
            end
            log("Run synchronously")
            items.create_cache_sync(buffers)
        end
    end)
end

---Get now candidates
---@return dic_data[]
function items.get()
    return items.use_cache
end

return items
