# cmp-dictionary

Dictionary completion source for [nvim-cmp](https://github.com/hrsh7th/nvim-cmp)

The easiest way to add your favorite completion candidates to nvim-cmp.

![image](https://user-images.githubusercontent.com/82267684/145278036-afa56b20-a365-4165-822f-98db5d7f11b1.png)

# Requirements

- neovim >= 0.7
- nvim-cmp

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
        max_items = 1000,
		capacity = 5,
		debug = false,
	})
```


</div></details>

See help for details.

# Examples of usage

## Add a so-called dictionary (a collection of common words in a language)

The easiest way to get the dictionary is to use aspell.
First, install aspell itself and the language you want.

For example on Ubuntu:
```sh
# English dictionary
sudo apt install aspell aspell-en
```

Next, run following command to get a dictionary file for this plugin (plain text).

```sh
aspell -d <lang> dump master | aspell -l <lang> expand > my.dict
```

If you only use one language, registering with `*` is useful, and if you want to switch between multiple languages, I recommend using spelllang.

```lua
require("cmp_dictionary").setup({
    dic = {
        -- If you always use the English dictionary, The following settings are suitable:
        ["*"] = "/path/to/en.dict",
        spelllang = {
            -- If you want to switch between English and German.
            en = "/path/to/en.dict",
            de = "/path/to/de.dict",
        },
    },
})
```

To switch between dictionaries registered in spelllang, follow the steps below.

1. Set spelllang to the language you want to use. 
2. Fire `CmpDictionaryUpdate`.

```vim
:set spelllang=de
:CmpDictionaryUpdate
```

It might be useful to have it as a command.

```vim
command -nargs=1 SwitchLang call s:switch_lang('<args>')
function! s:switch_lang(lang) abort
    execute 'set spelllang=' . a:lang
    CmpDictionaryUpdate
endfunction
```

## Editing files that have fixed keywords (some kind of configuration file, etc.)

For example, dein.vim (Shougo's ware) can be written plugin configuration for each in the toml file, and the keywords are fixed.
Therefore, it would be convenient to prepare the following dictionary file and use it in `dein.toml`.

```
hook_add
hook_source
... etc.
```

```lua
require("cmp_dictionary").setup({
    dic = {
        filepath = {
            -- By using the lua pattern, it supports file names like 'dein.toml' and 'deinlazy.toml'.
            ["dein.*%.toml"] = "/path/to/dein.dict"
        },
    },
})
```
