# cmp-dictionary

Dictionary completion source for [nvim-cmp](https://github.com/hrsh7th/nvim-cmp).

The easiest way to add your favorite completion candidates to nvim-cmp.

![image](https://user-images.githubusercontent.com/82267684/145278036-afa56b20-a365-4165-822f-98db5d7f11b1.png)

# Requirements

- neovim >= 0.7
- nvim-cmp
- plenary.nvim (only document feature)

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
    spelllang = {
      en = "path/to/english.dic",
    },
  },
  -- The following are default values.
  exact = 2,
  first_case_insensitive = false,
  document = false,
  document_command = "wn %s -over",
  async = false, 
  max_items = -1,
  capacity = 5,
  debug = false,
})
```


</div></details>

See help for details.

# Examples of usage

See [wiki](https://github.com/uga-rosa/cmp-dictionary/wiki/Examples-of-usage)
