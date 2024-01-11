---@class TrieNode
---@field children table<string, TrieNode>
---@field end_of_word boolean
local TrieNode = {}

---@return TrieNode
function TrieNode.new()
  return { children = {}, end_of_word = false }
end

---@class Trie
---@field root TrieNode
local Trie = {}

---@return Trie
function Trie.new()
  return setmetatable({
    root = TrieNode.new(),
  }, { __index = Trie })
end

---@param word string
function Trie:insert(word)
  local current = self.root
  for char in vim.gsplit(word, "") do
    local node = current.children[char] or TrieNode.new()
    current.children[char] = node
    current = node
  end
  current.end_of_word = true
end

---@private
---@param node TrieNode
---@param prefix string
---@param word_list string[]
function Trie:search_prefix(node, prefix, word_list)
  if node.end_of_word then
    table.insert(word_list, prefix)
  end
  for char, child in pairs(node.children) do
    self:search_prefix(child, prefix .. char, word_list)
  end
end

---@param prefix string
---@return string[]
function Trie:search(prefix)
  local node = self.root
  for char in vim.gsplit(prefix, "") do
    node = node.children[char]
    if node == nil then
      return {}
    end
  end
  local word_list = {}
  self:search_prefix(node, prefix, word_list)
  return word_list
end

return Trie
