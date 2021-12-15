---@alias dic_data {item: table, index: table}

---@class items
---@field cache LfuCache cached dictionary data (lfu)
---@field use_cache dic_data[] Currently dictionary data
---@field post string post dictionary
---@field now string now dictionary
local items = {}
items.post = {}

local fn = vim.fn
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

local function check_cache(dic)
    dic = type(dic) == "table" and dic or { dic }
    local no = {}
    local count = 0
    for _, d in ipairs(dic) do
        local path = fn.expand(d)
        if fn.filereadable(path) == 1 then
            count = count + 1
            local cache = items.cache:get(path)
            if cache then
                table.insert(items.use_cache, cache)
            else
                table.insert(no, path)
            end
        else
            echo("No such file: " .. path, true)
        end
    end
    return no, count
end

local function tbl_equal(t1, t2)
    vim.validate({
        t1 = { t1, "table" },
        t2 = { t2, "table" },
    })

    if t1 == t2 then
        return true
    end

    local set = {}
    for k1, v1 in pairs(t1) do
        if v1 ~= t2[k1] then
            return false
        end
        set[k1] = true
    end

    for k2 in pairs(t2) do
        if not set[k2] then
            return false
        end
    end

    return true
end

function items.update()
    if not config.ready then
        echo("The configuration method has changed, please use setup (check README for details).", true)
        return
    end

    local dic = config.get("dic")
    items.now = dic[vim.bo.filetype] or dic["*"]

    if tbl_equal(items.now, items.post) then
        echo("No change")
        return
    end

    items.post = items.now
    items.use_cache = {}

    local paths, num_dic = check_cache(items.now)

    if num_dic == 0 then
        echo("No dictionary loaded")
        return
    end

    local buffers = {}

    for _, path in ipairs(paths) do
        local name = fn.fnamemodify(path, ":t")

        uv.fs_open(path, "r", 438, function(err, fd)
            assert(not err, err)
            uv.fs_fstat(fd, function(err2, stat)
                assert(not err2, err2)
                uv.fs_read(fd, stat.size, 0, function(err3, buffer)
                    assert(not err3, err3)
                    uv.fs_close(fd, function(err4)
                        assert(not err4, err4)
                        table.insert(buffers, { buffer = buffer, path = path, name = name })
                        echo(path .. " are loaded")
                    end)
                end)
            end)
        end)
    end

    local timer = uv.new_timer()
    timer:start(0, 100, function()
        if #buffers == #paths then
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
