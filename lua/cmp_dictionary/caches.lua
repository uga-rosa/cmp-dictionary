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

-- util
local function echo(msg, force)
    if force or config.get("debug") then
        print("[cmp-dictionary] " .. msg)
    end
end

-- cache
items.cache = lfu.init(config.get("capacity"))
items.use_cache = {}

---Create dictionary data from buffers
---@param buffers {path: string, name: string, buffer: string}[]
local function _create_cache(buffers, exact, async)
    local new_caches = {}

    if async then
        buffers = require("mpack").Unpacker()(buffers)
    end

    -- grouping by first some letters
    local function indexing(item)
        local index = {}

        if exact == -1 then
            for _, i in pairs(item) do
                if exact < #i.label then
                    exact = #i.label
                end
            end
        end

        for len = 1, exact do
            local s = 1
            while #item[s].label < len do
                s = s + 1
            end
            local _pre = item[s].label:sub(1, len)
            index[_pre] = { start = s }
            local pre
            for j = s + 1, #item do
                local i = item[j].label
                if #i >= len then
                    pre = i:sub(1, len)
                    if pre ~= _pre then
                        if index[_pre].last == nil then
                            index[_pre].last = j - 1
                        end
                        index[pre] = { start = j }
                        _pre = pre
                    end
                elseif not index[_pre].last then
                    index[_pre].last = j - 1
                end
            end
            index[_pre].last = #item
        end

        return { item = item, index = index }
    end

    -- vim.gsplit
    local function gsplit(s, sep, plain)
        local start = 1
        local done = false

        local function _pass(i, j, ...)
            if i then
                assert(j + 1 > start, "Infinite loop detected")
                local seg = s:sub(start, i - 1)
                start = j + 1
                return seg, ...
            else
                done = true
                return s:sub(start)
            end
        end

        return function()
            if done or (s == "" and sep == "") then
                return
            end
            if sep == "" then
                if start == #s then
                    done = true
                end
                return _pass(start + 1, start)
            end
            return _pass(s:find(sep, start, plain))
        end
    end

    for _, buf in ipairs(buffers) do
        local new_cache = {}
        local detail = "belong to `" .. buf.name .. "`"
        for w in gsplit(buf.buffer, "%s+") do
            if w ~= "" then
                table.insert(new_cache, { label = w, detail = detail })
            end
        end
        table.sort(new_cache, function(item1, item2)
            return item1.label < item2.label
        end)

        new_caches[buf.path] = indexing(new_cache)
        new_caches[buf.path].mtime = buf.mtime
    end

    if async then
        return require("mpack").Packer()(new_caches)
    end
    return new_caches
end

function items.create_cache_sync(buffers, exact)
    for path, cache in pairs(_create_cache(buffers, exact, false)) do
        items.cache:set(path, cache)
        table.insert(items.use_cache, cache)
    end
    echo("All dictionary loaded")
end

items.create_cache_async = uv.new_work(_create_cache, function(_cache)
    for path, cache in pairs(vim.mpack.decode(_cache)) do
        items.cache:set(path, cache)
        table.insert(items.use_cache, cache)
    end
    echo("All dictionary loaded")
end)

function items.should_update(dictionaries)
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
            else
                table.insert(updated_or_new, path)
            end
        else
            echo("No such file: " .. path, true)
        end
    end
    return updated_or_new
end

function items.update()
    local buftype = api.nvim_buf_get_option(0, "buftype")
    if buftype ~= "" then
        return
    end

    if not config.ready then
        echo("Setup has NOT been called.", true)
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

    local updated_or_new = items.should_update(dictionaries)
    if #updated_or_new == 0 then
        echo("No change")
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
                        echo(path .. " are loaded")
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
                    echo("Run asynchronously")
                    items.create_cache_async:queue(vim.mpack.encode(buffers), config.get("exact"), true)
                    return
                else
                    echo("Module `mpack` is not available", true)
                end
            end
            echo("Run synchronously")
            items.create_cache_sync(buffers, config.get("exact"))
        end
    end)
end

---Get now candidates
---@return dic_data[]
function items.get()
    return items.use_cache
end

return items
