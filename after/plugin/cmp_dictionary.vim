if exists("g:loaded_cmp_dictionary")
    finish
endif
let g:loaded_cmp_dictionary = 1

let g:cmp_dictionary_silent = get(g:, "cmp_dictionary_silent", v:true)
let g:cmp_dictionary_exact = get(g:, "cmp_dictionary_exact", 2)
let g:cmp_dictionary_async = get(g:, "cmp_dictionary_async", v:false)
let g:cmp_dictionary_capacity = get(g:, "cmp_dictionary_capacity", 5)
let g:cmp_dictionary_dir = get(g:, "cmp_dictionary_dir", stdpath("cache") .. "/cmp_dictionary/")

lua require("cmp").register_source("dictionary", require("cmp_dictionary").new())

lua require("cmp_dictionary.caches").update()
augroup _cmp_dictionary_
    autocmd!
    autocmd FileType * lua require("cmp_dictionary.caches").update()
augroup END
