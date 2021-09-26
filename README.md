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
