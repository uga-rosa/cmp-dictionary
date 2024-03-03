# WARNING

**This is no longer maintained.**
**I will archive it in due course.**

# cmp-dictionary

A dictionary completion source for [nvim-cmp](https://github.com/hrsh7th/nvim-cmp).

This plugin provides one of the easiest way to add desired completion candidates to nvim-cmp.

![image](https://user-images.githubusercontent.com/82267684/145278036-afa56b20-a365-4165-822f-98db5d7f11b1.png)

# Requirements

- neovim >= 0.7
- nvim-cmp
- `vim.system()` or [plenary.nvim](https://github.com/nvim-lua/plenary.nvim) (for some optional features).

# Setting

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
  paths = { "/usr/share/dict/words" },
  exact_length = 2,
  first_case_insensitive = true,
  document = {
    enable = true,
    command = { "wn", "${label}", "-over" },
  },
})
```

See help for details.
