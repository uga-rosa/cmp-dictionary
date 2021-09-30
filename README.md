# cmp-user_dictionary

User dictionary completion source for [nvim-cmp](https://github.com/hrsh7th/nvim-cmp)  
See `:h 'dictionary'`  
It only reads the dictionary on startup, so please restart neovim after updating the dictionary.

## setup

```lua
require("cmp").setup({
  -- other settings
  sources = {
    { name = "user_dictionary" }
  }
})
```
## Configuration
you can download dic from [aspell.net](https://ftp.gnu.org/gnu/aspell/dict/0index.html) or installing by package manager , xbps extract to 
```bash
$ ls /usr/share/dict/

american-english  british-english  words
```
to pick any dic with `neovim/vim` you can use `set dictionary`:
```lua
vim.cmd('set dictionary+=/usr/share/dict/words')
...
```
