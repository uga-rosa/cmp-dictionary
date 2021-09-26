local M = {}

local f = vim.fn

M.new = function()
  return setmetatable({}, { __index = M })
end

local dictionaries = vim.api.nvim_get_option("dictionary")

local available_paths = (function()
  if dictionaries == "" then
    print("No dictionary set")
    return {}
  end
  local result = {}
  local paths = vim.split(dictionaries, ",")
  for _, path in ipairs(paths) do
    local p = f.expand(path)
    if f.filereadable(p) == 1 then
      result[#result + 1] = p
    else
      print("[cmp_user_dictionary] No such file: " .. p)
    end
  end
  return result
end)()

local loaded = false

local items = (function()
  local result = {}
  for _, path in ipairs(available_paths) do
    for line in io.lines(path) do
      local words = vim.split(line, "%s")
      for _, word in ipairs(words) do
        result[#result + 1] = { label = word }
      end
    end
  end
  loaded = #result ~= 0
  return result
end)()

function M:is_available()
  return loaded
end

function M:complete(_, callback)
  callback(items)
end

return M
