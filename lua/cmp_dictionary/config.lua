local u = require("cmp_dictionary.lib.unknown")
local is = u.is

---@class cmp.dictionary.options
---@field paths string[]
---@field exact_length integer
---@field first_case_insensitive boolean
---@field max_number_items integer
---@field document { enable: boolean, command: string[] }
---@field external { enable: boolean, command: string[] }
local default = {
  paths = {},
  exact_length = 2,
  first_case_insensitive = false,
  max_number_items = 0,
  document = {
    enable = false,
    command = {},
  },
  external = {
    enable = true,
    command = { "look", "${prefix}", "${path}" },
  },
}

local isOptions = is.TableOf({
  paths = is.OptionalOf(is.ListOf(is.String)),
  exact_length = is.OptionalOf(is.Number),
  first_case_insensitive = is.OptionalOf(is.Boolean),
  max_number_items = is.OptionalOf(is.Number),
  document = is.OptionalOf(is.TableOf({
    enable = is.OptionalOf(is.Boolean),
    command = is.OptionalOf(is.ListOf(is.String)),
  })),
  external = is.OptionalOf(is.TableOf({
    enable = is.OptionalOf(is.Boolean),
    command = is.OptionalOf(is.ListOf(is.String)),
  })),
})

---@param msg string
---@param ... unknown
local function warning(msg, ...)
  msg = string.format(msg, ...)
  vim.notify("[cmp-dictionary] " .. msg, vim.log.levels.WARN)
end

---@param opts table
---@param old_key string
---@param new_key? string
local function _fix(opts, old_key, new_key)
  if opts[old_key] then
    if new_key then
      warning("'%s' is deprecated. Use '%s' instead.", old_key, new_key)
      opts[new_key] = opts[old_key]
      opts[old_key] = nil
    else
      warning("'%s' is deprecated.", old_key)
      opts[old_key] = nil
    end
  end
end

---@param opts table
local function fixDeprecated(opts)
  _fix(opts, "exact", "exact_length")
  _fix(opts, "max_items", "max_number_items")
  _fix(opts, "document")
  _fix(opts, "sqlite")
  _fix(opts, "capacity")
end

---@param opts table
local function validator(opts)
  fixDeprecated(opts)
  u.assert(opts, isOptions)
end

local M = {}

---@type cmp.dictionary.options
M.options = default

function M.setup(opts)
  opts = opts or {}
  validator(opts)
  M.options = vim.tbl_deep_extend("force", {}, default, M.options, opts)

  if opts.paths then
    require("cmp_dictionary").update()
  end
end

return M
