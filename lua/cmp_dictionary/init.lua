local source = {}

source.new = function()
    local self = setmetatable({}, { __index = source })
    return self
end

local f = vim.fn
local a = vim.api
local uv = vim.loop

if vim.g.cmp_dictionary_silent == nil then
    vim.g.cmp_dictionary_silent = true
end

if vim.g.cmp_dictionary_exact == nil then
    vim.g.cmp_dictionary_exact = 2
end

local echo = function(msg)
    if not vim.g.cmp_dictionary_silent then
        print("[cmp-dictionary] " .. msg)
    end
end

local function tbl_len(tbl)
    local res = 0
    for _ in pairs(tbl) do
        res = res + 1
    end
    return res
end

local function comp(items1, items2)
    return items1.label < items2.label
end

local post_dic, dictionaries
local items = {}
local indexes = {}
local loaded = false

function source:is_available()
    return loaded
end

source.read_dictionary = function()
    post_dic = dictionaries

    do
        local is_buf, dic = pcall(a.nvim_buf_get_option, 0, "dictionary")
        dictionaries = is_buf and dic or a.nvim_get_option("dictionary")
    end

    if post_dic == dictionaries then
        echo("No change")
        return
    end

    local paths = (function()
        if dictionaries == "" then
            return {}
        end
        local result = {}
        local dics = vim.split(dictionaries, ",")
        for _, dic in ipairs(dics) do
            local path = f.expand(dic)
            if f.filereadable(path) == 1 then
                local name = f.fnamemodify(path, ":t")
                result[name] = path
            else
                echo("No such file: " .. path)
            end
        end
        return result
    end)()

    if tbl_len(paths) == 0 then
        echo("No dictionary loaded")
        loaded = false
        return
    end

    local datas = {}

    for name, path in pairs(paths) do
        uv.fs_open(path, "r", 438, function(err, fd)
            assert(not err, err)
            uv.fs_fstat(fd, function(err2, stat)
                assert(not err2, err2)
                uv.fs_read(fd, stat.size, 0, function(err3, data)
                    assert(not err3, err3)
                    uv.fs_close(fd, function(err4)
                        assert(not err4, err4)
                        datas[name] = data
                    end)
                end)
            end)
        end)
    end

    items = {}

    local timer = uv.new_timer()
    timer:start(0, 100, function()
        if tbl_len(datas) == tbl_len(paths) then
            for name, data in pairs(datas) do
                local detail = "belong to `" .. name .. "`"
                for w in vim.gsplit(data, "%s+") do
                    if w ~= "" then
                        table.insert(items, { label = w, detail = detail })
                    end
                end
            end

            if #items == 0 then
                timer:close()
                loaded = false
                echo("Only empty dictionaries")
                return
            end

            table.sort(items, comp)

            local max_len = vim.g.cmp_dictionary_exact
            if max_len == -1 then
                for _, item in pairs(items) do
                    if max_len < #item.label then
                        max_len = #item.label
                    end
                end
            end

            for len = 1, max_len do
                local s = 1
                while #items[s].label < len do
                    s = s + 1
                end
                local _pre = items[s].label:sub(1, len)
                indexes[_pre] = { start = s }
                local pre
                for j = s + 1, #items do
                    local item = items[j].label
                    if #item >= len then
                        pre = item:sub(1, len)
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

            timer:close()
            loaded = true
            echo("All dictionaries are loaded")
        end
    end)
end

local chache = {
    req = "",
    result = {},
}

local get_candidate = function(req)
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
