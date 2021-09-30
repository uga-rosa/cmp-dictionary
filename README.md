# cmp-dictionary

Dictionary completion source for [nvim-cmp](https://github.com/hrsh7th/nvim-cmp)  

Use the dictionaries set in `dictionary` as the source for cmp.
`:h 'dictionary'`

## setup

```lua
require("cmp").setup({
  -- other settings
  sources = {
    -- other sources
    {
      name = "dictionary",
      -- If you use large dictionaries, this setting is recommended.
      keyword_length = 2,
    },
  }
})
```

## Configuration

You can download dic from [aspell.net](https://ftp.gnu.org/gnu/aspell/dict/0index.html) or installing by package manager , xbps extract to

```bash
$ ls /usr/share/dict/
american-english  british-english  words
```

to pick any dic with `neovim/vim` you can use `set dictionary`:

```vim
set dictionary+=/usr/share/dict/words
```

In lua

```lua
vim.opt.dictionary:append("/usr/share/dict/words")
```

If you just want an English dictionary, you can also use [cmp-look](https://github.com/octaltree/cmp-look).

## Update dictionary

When the filetype is changed, check the `dictionary` and update the dictionary if it is changed.
Updating only the contents of the dictionary will not detect it.

## Use different dictionaries for each filetype

To set the dictionaries for each filetype, use setlocal in autocmd.
setlocal does not pollute the global settings since it is only valid for that buffer.

```vim
augroup MyCmpDictionary
  au!
  au FileType markdown setlocal dictionary=/path/to/dic1,/path/to/dic2
augroup END
```

If you want to enable or disable this source itself by filetype, use [cmp.setup.buffer](https://github.com/hrsh7th/nvim-cmp#sources-type-tablecmpsourceconfig).

## Global options

`g:cmp_dictionary_silent` is a setting for whether to output debug messages.
The default settings are as follows.

```lua
vim.g.cmp_dictionary_silent = true
```
