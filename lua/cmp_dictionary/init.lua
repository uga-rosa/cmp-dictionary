local config = require("cmp_dictionary.config")

return {
  setup = config.setup,
  -- Override in after/plugin/cmp_dictionary.lua
  update = function() end,
}
