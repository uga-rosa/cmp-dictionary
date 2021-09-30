require("cmp").register_source("user_dictionary", require("cmp_user_dictionary").new())

vim.cmd([[
augroup _cmp_user_dictionary_
  au!
  au FileType * lua require("cmp_user_dictionary").read_dictionary()
augroup END
]])
