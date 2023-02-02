if exists("g:loaded_cmp_dictionary")
    finish
endif
let g:loaded_cmp_dictionary = 1

lua require("cmp").register_source("dictionary", require("cmp_dictionary.source").new())

command CmpDictionaryUpdate :lua require("cmp_dictionary").update()

augroup _cmp_dictionary_
    autocmd!
    autocmd BufEnter * CmpDictionaryUpdate
augroup END
