local util = require("cmp_dictionary.util")
local config = require("cmp_dictionary.config")
local Async = require("cmp_dictionary.kit.Async")
local api = vim.api
local fn = vim.fn

local SQLite = {}

---@return table db
function SQLite:open()
  if self.db then
    return self.db
  end

  local ok, sqlite = pcall(require, "sqlite")
  if not ok or sqlite == nil then
    error("[cmp-dictionary] sqlite.lua is not installed!")
  end

  local db_path = vim.fn.stdpath("data") .. "/cmp-dictionary.sqlite3"
  self.db = sqlite:open(db_path)
  if not self.db then
    error("[cmp-dictionary] Error in opening DB")
  end

  if not self.db:exists("dictionary") then
    self.db:create("dictionary", {
      filepath = { "text", primary = true },
      mtime = { "integer", required = true },
      valid = { "integer", default = 1 },
    })
  end

  if not self.db:exists("items") then
    self.db:create("items", {
      label = { "text", required = true },
      detail = { "text", required = true },
      filepath = { "text", required = true },
      documentation = "text",
    })
  end

  vim.api.nvim_create_autocmd("VimLeave", {
    group = vim.api.nvim_create_augroup("cmp-dictionary-database", {}),
    callback = function()
      self.db:close()
    end,
  })

  return self.db
end

function SQLite:exists_index(name)
  self:open()
  local result = self.db:eval("SELECT * FROM sqlite_master WHERE type = 'index' AND name = ?", name)
  return type(result) == "table" and #result == 1
end

local function need_to_load(db)
  local dictionaries = util.get_dictionaries()
  local updated_or_new = {}
  for _, dictionary in ipairs(dictionaries) do
    local path = fn.expand(dictionary)
    if util.bool_fn.filereadable(path) then
      local mtime = fn.getftime(path)
      local mtime_cache = db:select("dictionary", { select = "mtime", where = { filepath = path } })
      if mtime_cache[1] == nil or mtime_cache[1].mtime ~= mtime then
        table.insert(updated_or_new, path)
      end
    end
  end
  return updated_or_new
end

local read = Async.async(function(db, filepath)
  local buffer, stat = util.read_file_sync(filepath)
  local mtime = stat.mtime.sec
  db:update("dictionary", {
    where = { filepath = filepath },
    set = { mtime = mtime },
  })

  local name = fn.fnamemodify(filepath, ":t")
  local detail = string.format("belong to `%s`", name)
  local items = {}
  for w in vim.gsplit(buffer, "%s+") do
    if w ~= "" then
      table.insert(items, { label = w, detail = detail, filepath = filepath })
    end
  end
  db:insert("items", items)
  if SQLite:exists_index("labelindex") then
    db:execute("DROP INDEX labelindex")
  end
  db:execute("CREATE INDEX labelindex ON items(label)")
end)

local function update(db)
  local buftype = api.nvim_buf_get_option(0, "buftype")
  if buftype ~= "" then
    return
  end

  for _, filepath in ipairs(need_to_load(db)) do
    read(db, filepath)
  end
end

local DB = {}

function DB.update()
  local db = SQLite:open()
  util.debounce("update_db", function()
    update(db)
  end, 100)
end

---@param req string
---@return lsp.CompletionItem[] items
---@return boolean isIncomplete
function DB.request(req, _)
  local db = SQLite:open()
  local max_items = config.get("max_items")
  local items = db:eval(
    [[
    SELECT label, detail, documentation FROM items
      WHERE filepath IN (SELECT filepath FROM dictionary WHERE valid = 1)
      AND label GLOB :a
      LIMIT :b
    ]],
    { a = req .. "*", b = max_items }
  )
  if type(items) == "table" then
    return items, #items == max_items
  else
    return {}, false
  end
end

---@param completion_item lsp.CompletionItem
---@param callback fun(completion_item: lsp.CompletionItem|nil)
function DB.document(completion_item, callback)
  if completion_item.documentation then
    callback(completion_item)
    return
  end

  local db = SQLite:open()
  local label = completion_item.label
  require("cmp_dictionary.document")(completion_item, function(completion_item_)
    if completion_item_ and completion_item_.documentation then
      db:eval(
        "UPDATE items SET documentation = :a WHERE label = :b",
        { a = completion_item_.documentation, b = label }
      )
    end
    callback(completion_item_)
  end)
end

return DB
