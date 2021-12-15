if exists("g:loaded_cmp_dictionary")
    finish
endif
let g:loaded_cmp_dictionary = 1

lua require("cmp").register_source("dictionary", require("cmp_dictionary").new())

lua require("cmp_dictionary.caches").update()
augroup _cmp_dictionary_
    autocmd!
    autocmd BufEnter * lua require("cmp_dictionary.caches").update()
augroup END
