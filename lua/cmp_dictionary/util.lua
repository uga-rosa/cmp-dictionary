local uv = vim.loop

local M = {}

---@param vector string[]
---@param index integer
---@param key string
---@return boolean
local function ascending_order(vector, index, key)
  return vector[index] >= key
end

---@param vector unknown[]
---@param key string
---@param cb fun(vec: unknown[], idx: integer, key: string): boolean
---@return integer
function M.binary_search(vector, key, cb)
  local left = 0
  local right = #vector
  local isOK = cb or ascending_order

  -- (left, right]
  while right - left > 1 do
    local mid = math.floor((left + right) / 2)
    if isOK(vector, mid, key) then
      right = mid
    else
      left = mid
    end
  end

  return right
end

local timer = {}

local function stop(name)
  if timer[name] then
    timer[name]:stop()
    timer[name]:close()
    timer[name] = nil
  end
end

function M.debounce(name, callback, timeout)
  stop(name)
  timer[name] = uv.new_timer()
  timer[name]:start(
    timeout,
    0,
    vim.schedule_wrap(function()
      stop(name)
      callback()
    end)
  )
end

M.bool_fn = setmetatable({}, {
  __index = function(_, key)
    return function(...)
      local v = vim.fn[key](...)
      if not v or v == 0 or v == "" then
        return false
      elseif type(v) == "table" and next(v) == nil then
        return false
      end
      return true
    end
  end,
})

return M
