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
---@param limit integer
function Trie:search_prefix(node, prefix, word_list, limit)
  if limit >= 0 and #word_list >= limit then
    return
  end
  if node.end_of_word then
    table.insert(word_list, prefix)
  end
  for char, child in pairs(node.children) do
    self:search_prefix(child, prefix .. char, word_list, limit)
  end
end

---@param prefix string
---@param limit integer
---@return string[]
function Trie:search(prefix, limit)
  local node = self.root
  for char in vim.gsplit(prefix, "") do
    node = node.children[char]
    if node == nil then
      return {}
    end
  end
  local word_list = {}
  self:search_prefix(node, prefix, word_list, limit)
  return word_list
end

return Trie
