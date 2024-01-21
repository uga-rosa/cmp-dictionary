if vim.g.loaded_cmp_dictionary then
  return
end
vim.g.loaded_cmp_dictionary = true

local source = require("cmp_dictionary.source").new()
require("cmp").register_source("dictionary", source)

require("cmp_dictionary").update = function()
  source:_update()
end
