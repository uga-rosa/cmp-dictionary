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

local echo = function(msg)
  if not vim.g.cmp_dictionary_silent then
    print("[cmp-dictionary] " .. msg)
  end
end

local post_dic, dictionaries
local items = {}
local indexes = {}
local loaded = false

source.read_dictionary = function()
  post_dic = dictionaries

  local is_buf, dic = pcall(a.nvim_buf_get_option, 0, "dictionary")
  dictionaries = is_buf and dic or a.nvim_get_option("dictionary")

  if post_dic == dictionaries then
    echo("No change")
    return
  end

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

  for i = 1, #available_paths do
    uv.fs_open(available_paths[i], "r", 438, function(err1, fd)
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

  items = {}

  local timer = uv.new_timer()
  timer:start(0, 100, function()
    if #datas == #available_paths then
      local c = 0
      for i = 1, #datas do
        for d in vim.gsplit(datas[i], "%s+") do
          if d ~= "" then
            c = c + 1
            items[c] = d
          end
        end
      end

      table.sort(items)

      local len = 2
      local _pre = items[1]:sub(1, len)
      indexes[_pre] = { start = 1 }
      local pre
      for i = 2, #items do
        pre = items[i]:sub(1, len)
        if pre ~= _pre then
          indexes[_pre].last = i - 1
          indexes[pre] = { start = i }
          _pre = pre
        end
      end
      indexes[_pre].last = #items

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
    return {}
  end

  if chache.req ~= req then
    chache.req = req
    chache.result = {}

    local c = 0
    for i = index.start, index.last do
      c = c + 1
      chache.result[c] = { label = items[i] }
    end
  end

  return chache.result
end

function source:is_available()
  return loaded
end

function source:complete(request, callback)
  local req = string.sub(request.context.cursor_before_line, request.offset)
  local len = 2
  req = #req > len and req:sub(1, len) or req
  callback(get_candidate(req))
end

return source
