if vim.g.loaded_cmp_dictionary then
    return
end
vim.g.loaded_cmp_dictionary = true

require("cmp").register_source("dictionary", require("cmp_dictionary").new())

require("cmp_dictionary").update()

vim.cmd([[
augroup _cmp_dictionary_
    au!
    au FileType * lua require("cmp_dictionary").update()
augroup END
]])
