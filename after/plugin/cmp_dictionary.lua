if vim.g.loaded_cmp_dictionary then
  return
end
vim.g.loaded_cmp_dictionary = true

local source = require("cmp_dictionary.source").new()
require("cmp").register_source("dictionary", source)

---@param force? boolean
local function update(force)
  local opts = require("cmp_dictionary.config").options
  source.dict:update(opts.paths, force)
end

require("cmp_dictionary").update = update
update()
