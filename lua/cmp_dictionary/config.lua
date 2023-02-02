local M = {}

M.default = {
  exact = 2,
  first_case_insensitive = false,
  document = false,
  document_command = "wn %s -over",
  async = false,
  max_items = -1,
  capacity = 5,
  debug = false,
}
M.config = {}
M.ready = false

---@param opt table
function M.setup(opt)
  vim.validate({ opt = { opt, "table" } })

  M.config = vim.tbl_deep_extend("keep", opt, M.default)

  local c = assert(M.config)
  vim.validate({
    exact = { c.exact, "n" },
    first_case_insensitive = { c.first_case_insensitive, "b" },
    document = { c.document, "b" },
    document_command = { c.document_command, { "s", "t" } },
    async = { c.async, "b" },
    max_items = { c.max_items, "n" },
    capacity = { c.capacity, "n" },
    debug = { c.debug, "b" },
  })

  M.ready = true
end

---@param name string
---@return unknown
function M.get(name)
  return M.config[name]
end

return M
