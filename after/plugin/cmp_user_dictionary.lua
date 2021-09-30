require("cmp").register_source("dictionary", require("cmp_dictionary").new())

vim.cmd([[
augroup _cmp_dictionary_
  au!
  au FileType * lua require("cmp_dictionary").read_dictionary()
augroup END
]])
