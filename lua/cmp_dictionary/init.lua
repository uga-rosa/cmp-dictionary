local source = {}

source.new = function()
  local self = setmetatable({}, { __index = source })
  return self
end

local f = vim.fn
local a = vim.api
local uv = vim.loop

vim.g.cmp_dictionary_silent = true

local echo = function(msg)
  if not vim.g.cmp_dictionary_silent then
    print("[cmp-dictionary] " .. msg)
  end
end

local post_dic, dictionaries
local items = {}
local loaded = false

source.read_dictionary = function()
  post_dic = dictionaries

  local is_buf, dic = pcall(a.nvim_buf_get_option, 0, "dictionary")
  dictionaries = is_buf and dic or a.nvim_get_option("dictionary")

  if post_dic == dictionaries then
    echo("No change")
    return
  end

  items = {}

  local available_paths = (function()
    if dictionaries == "" then
      return {}
    end
    local result = {}
    local paths = vim.split(dictionaries, ",")
    for _, path in ipairs(paths) do
      local p = f.expand(path)
      if f.filereadable(p) == 1 then
        result[#result + 1] = p
      else
        echo("No such file: " .. p)
      end
    end
    return result
  end)()

  if #available_paths == 0 then
    echo("No dictionary loaded")
    loaded = false
    return
  end

  local datas = {}

  for _, path in ipairs(available_paths) do
    uv.fs_open(path, "r", 438, function(err1, fd)
      assert(not err1, err1)
      uv.fs_fstat(fd, function(err2, stat)
        assert(not err2, err2)
        uv.fs_read(fd, stat.size, 0, function(err3, data)
          assert(not err3, err3)
          uv.fs_close(fd, function(err4)
            assert(not err4, err4)
            datas[#datas + 1] = data
          end)
        end)
      end)
    end)
  end

  local timer = uv.new_timer()
  timer:start(0, 100, function()
    if #datas == #available_paths then
      for _, data in ipairs(datas) do
        for c in vim.gsplit(data, "%s") do
          items[#items + 1] = c
        end
      end
      table.sort(items)
      timer:close()
      loaded = true
      echo("All dictionaries are loaded")
    end
  end)
end

local get_candidate = function(req)
  if #items == 0 then
    return {}
  end
  local result = {}
  local flag = false
  for _, item in ipairs(items) do
    if vim.startswith(item, req) then
      result[#result + 1] = { label = item }
      if not flag then
        flag = true
      end
    elseif flag then
      break
    end
  end
  return { items = result, isIncomplete = true }
end

function source:is_available()
  return loaded
end

function source:complete(request, callback)
  local req = string.sub(request.context.cursor_before_line, request.offset)
  callback(get_candidate(req))
end

return source
