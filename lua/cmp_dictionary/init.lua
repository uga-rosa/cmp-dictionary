local M = {}

function M.setup(opt)
  require("cmp_dictionary.config").setup(opt)
end

function M.update()
  require("cmp_dictionary.caches").update()
end

return M
