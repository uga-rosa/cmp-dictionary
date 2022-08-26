local source = {}

local cmp = require("cmp")
local luv = vim.loop

local utf8 = require("cmp_dictionary.lib.utf8")
local caches = require("cmp_dictionary.caches")
local config = require("cmp_dictionary.config")
local util = require("cmp_dictionary.util")

function source.new()
    return setmetatable({}, { __index = source })
end

function source:is_available()
    return config.ready
end

function source.get_keyword_pattern()
    return [[\k\+]]
end

local candidate_cache = {
    req = "",
    items = {},
}

local function is_capital(str)
    return str:find("^%u") and true or false
end

local function to_lower_first(str)
    local l = str:gsub("^.", string.lower)
    return l
end

local function to_upper_first(str)
    local u = str:gsub("^.", string.upper)
    return u
end

local function get_from_caches(req)
    local items = {}

    local ok, offset, codepoint
    ok, offset = pcall(utf8.offset, req, -1)
    if not ok then
        return items
    end
    ok, codepoint = pcall(utf8.codepoint, req, offset)
    if not ok then
        return items
    end

    local req_next = req:sub(1, offset - 1) .. utf8.char(codepoint + 1)

    for _, cache in pairs(caches.get()) do
        local start = util.binary_search(cache.item, req, function(vector, index, key)
            return vector[index].label >= key
        end)
        local last = util.binary_search(cache.item, req_next, function(vector, index, key)
            return vector[index].label >= key
        end) - 1
        if start > 0 and last > 0 and start <= last then
            for i = start, last do
                local item = cache.item[i]
                item.label = item._label or item.label
                table.insert(items, item)
            end
        end
    end
    return items
end

function source.get_candidate(req, isIncomplete)
    if candidate_cache.req == req then
        return { items = candidate_cache.items, isIncomplete = isIncomplete }
    end

    local items = get_from_caches(req)

    if config.get("first_case_insensitive") then
        if is_capital(req) then
            for _, item in ipairs(get_from_caches(to_lower_first(req))) do
                item._label = item._label or item.label
                item.label = to_upper_first(item._label)
                table.insert(items, item)
            end
        else
            for _, item in ipairs(get_from_caches(to_upper_first(req))) do
                item._label = item._label or item.label
                item.label = to_lower_first(item._label)
                table.insert(items, item)
            end
        end
    end

    candidate_cache.req = req
    candidate_cache.items = items

    return { items = items, isIncomplete = isIncomplete }
end

function source:complete(request, callback)
    if caches.is_just_updated() then
        candidate_cache = {}
    end
    local exact = config.get("exact")

    ---@type string
    local line = request.context.cursor_before_line
    local offset = request.offset
    line = line:sub(offset)
    if line == "" then
        return
    end

    local req, isIncomplete
    if exact > 0 then
        local line_len = utf8.len(line)
        if line_len <= exact then
            req = line
            isIncomplete = line_len < exact
        else
            local last = exact
            if line_len ~= #line then
                last = utf8.offset(line, exact + 1) - 1
            end
            req = line:sub(1, last)
            isIncomplete = false
        end
    else
        -- must be -1
        req = line
        isIncomplete = true
    end

    callback(source.get_candidate(req, isIncomplete))
end

local document_cache = require("cmp_dictionary.lfu").init(100)

local function get_command(word)
    local command = config.get("document_command")

    local args
    if type(command) == "table" then
        -- copy
        args = {}
        for i, v in ipairs(command) do
            args[i] = v
        end
    elseif type(command) == "string" then
        args = vim.split(command, " ")
    end

    local cmd = table.remove(args, 1)
    for i, arg in ipairs(args) do
        if arg:find("%s", 1, true) then
            args[i] = arg:format(word)
        end
    end

    return cmd, args
end

local function pipes()
    local stdin = luv.new_pipe(false)
    local stdout = luv.new_pipe(false)
    local stderr = luv.new_pipe(false)
    return { stdin, stdout, stderr }
end

local function get_document(completion_item, callback)
    local word = completion_item.label
    local cmd, args = get_command(word)
    if not cmd then
        callback(completion_item)
        return
    end

    local stdio = pipes()
    local spawn_options = {
        args = args,
        stdio = stdio,
    }

    local handle
    handle = luv.spawn(cmd, spawn_options, function()
        stdio[1]:close()
        stdio[2]:close()
        stdio[3]:close()
        handle:close()
    end)

    if not handle then
        callback(completion_item)
        return
    end

    luv.read_start(stdio[2], function(err, result)
        assert(not err, err)
        result = result or ""
        document_cache:set(word, result)
        completion_item.documentation = {
            kind = cmp.lsp.MarkupKind.PlainText,
            value = result,
        }
        callback(completion_item)
    end)
end

function source:resolve(completion_item, callback)
    if config.get("document") then
        local cached = document_cache:get(completion_item.label)
        if cached then
            completion_item.documentation = {
                kind = cmp.lsp.MarkupKind.PlainText,
                value = cached,
            }
            callback(completion_item)
        else
            get_document(completion_item, callback)
        end
    else
        callback(completion_item)
    end
end

function source.setup(opt)
    config.setup(opt)
end

function source.update()
    caches.update()
end

return source
