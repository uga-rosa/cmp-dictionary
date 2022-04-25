local source = {}

local cmp = require("cmp")
local luv = vim.loop

local caches = require("cmp_dictionary.caches")
local config = require("cmp_dictionary.config")

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
    result = {},
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
    local result = {}
    for _, cache in pairs(caches.get()) do
        local index = cache.index[req]
        if index then
            for i = index.start, index.last do
                local item = cache.item[i]
                item.label = item._label or item.label
                table.insert(result, item)
            end
        end
    end
    return result
end

function source.get_candidate(req, isIncomplete)
    if candidate_cache.req == req then
        return { items = candidate_cache.result, isIncomplete = isIncomplete }
    end

    local result = get_from_caches(req)

    if config.get("first_case_insensitive") then
        if is_capital(req) then
            for _, item in ipairs(get_from_caches(to_lower_first(req))) do
                item._label = item._label or item.label
                item.label = to_upper_first(item._label)
                table.insert(result, item)
            end
        else
            for _, item in ipairs(get_from_caches(to_upper_first(req))) do
                item._label = item._label or item.label
                item.label = to_lower_first(item._label)
                table.insert(result, item)
            end
        end
    end

    candidate_cache.req = req
    candidate_cache.result = result

    return { items = result, isIncomplete = isIncomplete }
end

function source:complete(request, callback)
    local exact = config.get("exact")
    local req = request.context.cursor_before_line:sub(request.offset, request.offset + exact - 1)
    local isIncomplete = #req < exact
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
