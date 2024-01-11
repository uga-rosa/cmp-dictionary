local M = {}

---@alias Predicate<T> fun(x: unknown): boolean x is T

local is = {}
M.is = is

---x is nil
---@param x unknown
---@return boolean
function is.Nil(x)
  return x == nil
end

---x is boolean
---@param x unknown
---@return boolean
function is.Boolean(x)
  return type(x) == "boolean"
end

---x is string
---@param x unknown
---@return boolean
function is.String(x)
  return type(x) == "string"
end

---x is number
---@param x unknown
---@return boolean
function is.Number(x)
  return type(x) == "number"
end

---x is function
---@param x unknown
---@return boolean
function is.Function(x)
  return type(x) == "function"
end

---x is table
---@param x unknown
---@return boolean
function is.Table(x)
  return type(x) == "table"
end

---x is thread
---@param x unknown
---@return boolean
function is.Thread(x)
  return type(x) == "thread"
end

---x is userdata
---@param x unknown
---@return boolean
function is.Userdata(x)
  return type(x) == "userdata"
end

---@param x table
---@return integer
local function tbl_count(x)
  local count = 0
  for _ in pairs(x) do
    count = count + 1
  end
  return count
end

---Return a type predicate function that returns `true` if the type of `x` is `ObjectOf<T>`
---@param pred_tbl table<unknown, Predicate>
---@param opts? { strict?: boolean }
---@return fun(x: unknown): boolean pred x is type of pred_obj
function is.TableOf(pred_tbl, opts)
  return function(x)
    if not is.Table(x) then
      return false
    end
    for k, pred in pairs(pred_tbl) do
      if not pred(x[k]) then
        return false
      end
    end
    opts = opts or {}
    if not opts.strict then
      return true
    end
    return tbl_count(x) == tbl_count(pred_tbl)
  end
end

---x is list
---@param x unknown
---@return boolean
function is.List(x)
  if not is.Table(x) then
    return false
  end
  local num_elem = tbl_count(x)
  if num_elem == 0 then
    return getmetatable(x) ~= vim._empty_dict_mt
  else
    for i = 1, num_elem do
      if x[i] == nil then
        return false
      end
    end
    return true
  end
end

---Return a type predicate function that returns `true` if the type of `x` is `T[]`.
---@generic T
---@param pred Predicate<T>
---@return Predicate<T[]>
function is.ListOf(pred)
  ---@param x unknown
  ---@return boolean
  return function(x)
    if not is.List(x) then
      return false
    end
    for i = 1, #x do
      if not pred(x[i]) then
        return false
      end
    end
    return true
  end
end

---Return a type predicate function that returns `true` if the type of `x` is `T` or `nil`.
---@generic T
---@param pred Predicate<T>
---@return Predicate<T|nil>
function is.OptionalOf(pred)
  return function(x)
    return is.Nil(x) or pred(x)
  end
end

---Return a type predicate function that returns `true` if the type of `x` is `OneOf<T>`.
---@generic T
---@param preds Predicate<T>[]
---@return Predicate
function is.OneOf(preds)
  return function(x)
    for _, pred in ipairs(preds) do
      if pred(x) then
        return true
      end
    end
    return false
  end
end

---@param x unknown
---@param pred Predicate
function M.assert(x, pred)
  assert(pred(x))
end

---@generic T
---@param x unknown
---@param pred Predicate<T>
---@return T
function M.ensure(x, pred)
  M.assert(x, pred)
  return x
end

---@generic T
---@param x unknown
---@param pred Predicate<T>
---@return T|nil
function M.maybe(x, pred)
  if pred(x) then
    return x
  end
end

return M
