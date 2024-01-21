return {
  setup = require("cmp_dictionary.config").setup,
  switcher = function()
    vim.notify("[cmp-dictionary] switcher is deprecated.\nSee `:h cmp-dictionary-option-paths`", vim.log.levels.ERROR)
  end,
  -- Override in after/plugin/cmp_dictionary.lua
  update = function() end,
}
