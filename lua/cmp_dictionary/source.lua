local source = {}

local utf8 = require("cmp_dictionary.lib.utf8")
local caches = require("cmp_dictionary.caches")
local config = require("cmp_dictionary.config")
local util = require("cmp_dictionary.util")

function source.new()
  return setmetatable({}, { __index = source })
end

---@return boolean
function source:is_available()
  return config.ready
end

---@return string
function source.get_keyword_pattern()
  return [[\k\+]]
end

local candidate_cache = {
  req = "",
  items = {},
}

---@param str string
---@return boolean
local function is_capital(str)
  return str:find("^%u") and true or false
end

---@param str string
---@return string
local function to_lower_first(str)
  local l = str:gsub("^.", string.lower)
  return l
end

---@param str string
---@return string
local function to_upper_first(str)
  local u = str:gsub("^.", string.upper)
  return u
end

---@param req string
---@param isIncomplete? boolean
---@return table
---@return boolean?
local function get_from_caches(req, isIncomplete)
  local items = {}

  local ok, offset, codepoint
  ok, offset = pcall(utf8.offset, req, -1)
  if not ok then
    return items, isIncomplete
  end
  ok, codepoint = pcall(utf8.codepoint, req, offset)
  if not ok then
    return items, isIncomplete
  end

  local req_next = req:sub(1, offset - 1) .. utf8.char(codepoint + 1)

  local max_items = config.get("max_items")
  for _, cache in pairs(caches.get()) do
    local start = util.binary_search(cache.item, req, function(vector, index, key)
      return vector[index].label >= key
    end)
    local last = util.binary_search(cache.item, req_next, function(vector, index, key)
      return vector[index].label >= key
    end) - 1
    if start > 0 and last > 0 and start <= last then
      if max_items > 0 and last >= start + max_items then
        last = start + max_items
        isIncomplete = true
      end
      for i = start, last do
        local item = cache.item[i]
        item.label = item._label or item.label
        table.insert(items, item)
      end
    end
  end
  return items, isIncomplete
end

---@param req string
---@param isIncomplete? boolean
---@return table
function source.get_candidate(req, isIncomplete)
  if candidate_cache.req == req then
    return { items = candidate_cache.items, isIncomplete = isIncomplete }
  end

  local items
  items, isIncomplete = get_from_caches(req, isIncomplete)

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

---@param request cmp.SourceCompletionApiParams
---@param callback fun(response: lsp.CompletionResponse|nil)
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

function source:resolve(completion_item, callback)
  require("cmp_dictionary.document")(completion_item, callback)
end

return source
