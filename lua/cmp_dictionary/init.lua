local source = {}

local caches = require("cmp_dictionary.caches")
local merge = require("cmp_dictionary.merge")
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

function source.get_candidate(req)
    if candidate_cache.req == req then
        return { items = candidate_cache.result, isIncomplete = true }
    end

    local result = {}
    for _, cache in pairs(caches.get()) do
        local index = cache.index[req]
        if index then
            local items = {}
            for i = index.start, index.last do
                table.insert(items, cache.item[i])
            end
            table.insert(result, items)
        end
    end

    if #result > 1 then
        result = merge(result, function(item1, item2)
            return item1.label < item2.label
        end)
    elseif #result == 1 then
        result = result[1]
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
