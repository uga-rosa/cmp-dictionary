# cmp-dictionary

Dictionary completion source for [nvim-cmp](https://github.com/hrsh7th/nvim-cmp)  

## Setup

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
        ["*"] = "/usr/share/dict/words",
        ["markdown"] = { "path/to/mddict", "path/to/mddict2" },
    },
    -- The following are default values, so you don't need to write them if you don't want to change them
    exact = 2,
    async = false, 
    capacity = 5,
    debug = false, 
})
```

#### dic (table, default { [*] = {} })

The key is the file type, and the value is an array of dictionary paths.
If one dictionary, you can use a string instead of an array.
The key `*` is used as a global setting.

#### exact (integer, default 2)

It decides how many characters at the beginning are used as the exact match.
If -1, only candidates with an exact prefix match will be returns.  

The default value is 2.  
![image](https://user-images.githubusercontent.com/82267684/145278036-afa56b20-a365-4165-822f-98db5d7f11b1.png)

If set to -1.  
![image](https://user-images.githubusercontent.com/82267684/145278316-1de264eb-86f8-4293-b20b-e3462efb2b68.png)

#### async (boolean, default false)

If true, perform the initialization in a separate thread.
If you are using a very large dictionary and the body operation is blocked, try this.

You need module mpack, so you need to install lua51-mpack or build neovim of 0.6 or higher.

#### capacity (integer, default 5)

Determines the maximum number of dictionaries to be cached.
This will prevent duplicate reads when you switch dictionaries with the settings described above.

#### debug (boolean, default false)

If true, debug messages are output.

## Where to find dictionaries

You can download dic from [aspell.net](https://ftp.gnu.org/gnu/aspell/dict/0index.html) or installing by package manager, xbps extract to

```bash
$ ls /usr/share/dict/
american-english  british-english  words
```

## How to create your own dictionary

The dictionary is recognized as a list delimited by `%s`. `%s` is a space, `\t`, `\n`, `\r`, or `\f`.
For example, if you use the following file as a dictionary, the source to be added is `{"hello", "world", "!"}`.

```txt
hello
world !
```
