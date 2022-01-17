local source = {}

local caches = require("cmp_dictionary.caches")
local config = require("cmp_dictionary.config")

function source.new()
    return setmetatable({}, { __index = source })
end

function source:is_available()
    return config.ready
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

function source.get_candidate(req)
    if candidate_cache.req == req then
        return { items = candidate_cache.result, isIncomplete = true }
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

    return { items = result, isIncomplete = true }
end

function source:complete(request, callback)
    local req = request.context.cursor_before_line:sub(request.offset, request.offset + config.get("exact"))
    callback(source.get_candidate(req))
end

function source.setup(opt)
    config.setup(opt)
end

return source
