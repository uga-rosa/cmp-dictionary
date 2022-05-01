# cmp-dictionary

Dictionary completion source for [nvim-cmp](https://github.com/hrsh7th/nvim-cmp)

![image](https://user-images.githubusercontent.com/82267684/145278036-afa56b20-a365-4165-822f-98db5d7f11b1.png)

# Requires

- neovim >= 0.7
- [nvim-cmp](https://github.com/hrsh7th/nvim-cmp)

# Usage

Example setting

```lua
require("cmp").setup({
  -- other settings
  sources = {
    -- other sources
    {
      name = "dictionary",
      keyword_length = 2,
    },
  }
})

require("cmp_dictionary").setup({
    dic = {
        ["*"] = { "/usr/share/dict/words" },
        ["lua"] = "path/to/lua.dic",
        ["javascript,typescript"] = { "path/to/js.dic", "path/to/js2.dic" },
        filename = {
            ["xmake.lua"] = { "path/to/xmake.dic", "path/to/lua.dic" },
        },
        filepath = {
            ["%.tmux.*%.conf"] = "path/to/tmux.dic"
        },
    },
    -- The following are default values, so you don't need to write them if you don't want to change them
    exact = 2,
    first_case_insensitive = false,
    document = false,
    document_command = "wn %s -over",
    async = false, 
    capacity = 5,
    debug = false,
})
```

See help for details.
