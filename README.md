# cmp-dictionary

Dictionary completion source for [nvim-cmp](https://github.com/hrsh7th/nvim-cmp).

The easiest way to add your favorite completion candidates to nvim-cmp.

![image](https://user-images.githubusercontent.com/82267684/145278036-afa56b20-a365-4165-822f-98db5d7f11b1.png)

# Requirements

- neovim >= 0.7
- nvim-cmp
- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim) (only document feature)
- [sqlite.lua](https://github.com/kkharji/sqlite.lua) (only if sqlite option is enabled)

# Setting

<details><summary>Example setting</summary><div>


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

local dict = require("cmp_dictionary")

dict.setup({
  -- The following are default values.
  exact = 2,
  first_case_insensitive = false,
  document = false,
  document_command = "wn %s -over",
  async = false,
  sqlite = false,
  max_items = -1,
  capacity = 5,
  debug = false,
})

dict.switcher({
  filetype = {
    lua = "/path/to/lua.dict",
    javascript = { "/path/to/js.dict", "/path/to/js2.dict" },
  },
  filepath = {
    [".*xmake.lua"] = { "/path/to/xmake.dict", "/path/to/lua.dict" },
    ["%.tmux.*%.conf"] = { "/path/to/js.dict", "/path/to/js2.dict" },
  },
  spelllang = {
    en = "/path/to/english.dict",
  },
})
```


</div></details>

See help for details.

# Examples of usage

See [wiki](https://github.com/uga-rosa/cmp-dictionary/wiki/Examples-of-usage)
