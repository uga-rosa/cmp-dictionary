local f = vim.fn
local a = vim.api
local uv = vim.loop
local ok, mpack = pcall(require, "mpack")

-- util
local function echo(msg, force)
    if force or not vim.g.cmp_dictionary_silent then
        print("[cmp-dictionary] " .. msg)
    end
end

-- body
local source = {}

function source.new()
    return setmetatable({}, { __index = source })
end

local post_dic, dictionaries
local items = {}
local indexes = {}

function source:is_available()
    return #items ~= 0
end

local index_async = uv.new_work(function(buffer, exact)
    ---@diagnostic disable-next-line: redefined-local
    local mpack = require("mpack")

    -- Since it is a separate thread, global variables such as `vim` cannot be used.
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

    local items_ = {}

    for name, data in pairs(mpack.Unpacker()(buffer)) do
        local detail = "belong to `" .. name .. "`"
        for w in gsplit(data, "%s+") do
            if w ~= "" then
                table.insert(items_, { label = w, detail = detail })
            end
        end
    end

    if #items_ == 0 then
        return
    end

    table.sort(items_, function(item1, item2)
        return item1.label < item2.label
    end)

    if exact == -1 then
        for _, i in pairs(items_) do
            if exact < #i.label then
                exact = #i.label
            end
        end
    end

    local indexes_ = {}

    for len = 1, exact do
        local s = 1
        while #items_[s].label < len do
            s = s + 1
        end
        local _pre = items_[s].label:sub(1, len)
        indexes_[_pre] = { start = s }
        local pre
        for j = s + 1, #items_ do
            local i = items_[j].label
            if #i >= len then
                pre = i:sub(1, len)
                if pre ~= _pre then
                    if indexes_[_pre].last == nil then
                        indexes_[_pre].last = j - 1
                    end
                    indexes_[pre] = { start = j }
                    _pre = pre
                end
            elseif indexes_[_pre].last == nil then
                indexes_[_pre].last = j - 1
            end
        end
        indexes_[_pre].last = #items_
    end

    return mpack.Packer()(items_), mpack.Packer()(indexes_)
end, function(items_, indexes_)
    if items_ then
        items = mpack.Unpacker()(items_)
        indexes = mpack.Unpacker()(indexes_)
        echo("All dictionaries are loaded")
    else
        echo("Only empty dictionaries")
    end
end)

local index_sync = function(buffer, exact)
    for name, data in pairs(buffer) do
        local detail = "belong to `" .. name .. "`"
        for w in vim.gsplit(data, "%s+") do
            if w ~= "" then
                table.insert(items, { label = w, detail = detail })
            end
        end
    end

    if #items == 0 then
        echo("Only empty dictionaries")
        return
    end

    table.sort(items, function(item1, item2)
        return item1.label < item2.label
    end)

    if exact == -1 then
        for _, i in pairs(items) do
            if exact < #i.label then
                exact = #i.label
            end
        end
    end

    for len = 1, exact do
        local s = 1
        while #items[s].label < len do
            s = s + 1
        end
        local _pre = items[s].label:sub(1, len)
        indexes[_pre] = { start = s }
        local pre
        for j = s + 1, #items do
            local i = items[j].label
            if #i >= len then
                pre = i:sub(1, len)
                if pre ~= _pre then
                    if indexes[_pre].last == nil then
                        indexes[_pre].last = j - 1
                    end
                    indexes[pre] = { start = j }
                    _pre = pre
                end
            elseif indexes[_pre].last == nil then
                indexes[_pre].last = j - 1
            end
        end
        indexes[_pre].last = #items
    end

    echo("All dictionaries are loaded")
end

function source.update()
    post_dic = dictionaries

    do
        local is_buf, dic = pcall(a.nvim_buf_get_option, 0, "dictionary")
        dictionaries = is_buf and dic or a.nvim_get_option("dictionary")
    end

    if post_dic == dictionaries then
        echo("No change")
        return
    end

    items = {}
    indexes = {}

    local paths = {}
    local number_of_paths = 0

    if dictionaries ~= "" then
        for dic in vim.gsplit(dictionaries, ",") do
            local path = f.expand(dic)
            if f.filereadable(path) == 1 then
                local name = f.fnamemodify(path, ":t")
                paths[name] = path
                number_of_paths = number_of_paths + 1
            else
                echo("No such file: " .. path)
            end
        end
    end

    if number_of_paths == 0 then
        echo("No dictionary loaded")
        return
    end

    local read_count = 0
    local buffers = {}

    for name, path in pairs(paths) do
        uv.fs_open(path, "r", 438, function(err, fd)
            assert(not err, err)
            uv.fs_fstat(fd, function(err2, stat)
                assert(not err2, err2)
                uv.fs_read(fd, stat.size, 0, function(err3, buffer)
                    assert(not err3, err3)
                    uv.fs_close(fd, function(err4)
                        assert(not err4, err4)
                        buffers[name] = buffer
                        echo(path .. " are loaded")
                        read_count = read_count + 1
                    end)
                end)
            end)
        end)
    end

    local timer = uv.new_timer()
    timer:start(0, 100, function()
        if read_count == number_of_paths then
            timer:stop()
            timer:close()
            if vim.g.cmp_dictionary_async then
                if ok then
                    echo("Run asynchronously")
                    index_async:queue(mpack.Packer()(buffers), vim.g.cmp_dictionary_exact)
                    return
                else
                    echo("Module `mpack` is not available", true)
                end
            end
            echo("Run synchronously")
            index_sync(buffers, vim.g.cmp_dictionary_exact)
        end
    end)
end

local chache = {
    req = "",
    result = {},
}

local function get_candidate(req)
    local index = indexes[req]
    if not index then
        return { items = {}, isIncomplete = true }
    end

    if chache.req ~= req then
        chache.req = req
        chache.result = {}
        for i = index.start, index.last do
            table.insert(chache.result, items[i])
        end
    end

    return { items = chache.result, isIncomplete = true }
end

function source:complete(request, callback)
    local req = string.sub(request.context.cursor_before_line, request.offset)
    local len = vim.g.cmp_dictionary_exact
    req = #req > len and req:sub(1, len) or req
    callback(get_candidate(req))
end

return source
