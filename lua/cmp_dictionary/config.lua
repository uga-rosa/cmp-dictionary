---@class CmpDictionaryOptions
---@field paths string[]
---@field exact integer
---@field first_case_insensitive boolean
---@field max_items integer
---@field document_command string[]
---@field grep_command string[]
local default = {
  paths = {},
  exact = 2,
  first_case_insensitive = false,
  max_items = 0,
  document_command = {},
  grep_command = {},
}

---@param opt table
local function validator(opt)
  vim.validate({
    opt = { opt, "t" },
    ["opt.paths"] = { opt.paths, "table", true },
    ["opt.exact"] = { opt.exact, "number", true },
    ["opt.first_case_insensitive"] = { opt.first_case_insensitive, "boolean", true },
    ["opt.max_items"] = { opt.max_items, "number", true },
    ["opt.document_command"] = { opt.document_command, "table", true },
    ["opt.grep_command"] = { opt.grep_command, "table", true },
  })
end

local M = {}

---@type CmpDictionaryOptions
M.options = default

function M.setup(opt)
  opt = opt or {}
  validator(opt)
  M.options = vim.tbl_extend("force", {}, default, opt)
end

return M
