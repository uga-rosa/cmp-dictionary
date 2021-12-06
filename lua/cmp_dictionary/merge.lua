---@class Node
---@field value any Value of the node
---@field index integer Index of the value of the array
---@field array array Array to which the value belongs
---@field parent Node Parent node
---@field lc Node loser side child node
---@field wc Node winner side child node
---@field winner Node Winner's node
local Node = {}

---Create new node
---@overload fun(array: array): Node @leaf
---@overload fun(lc: Node, wc: Node): Node @internal or root
---@return Node
function Node.init(...)
    local self = setmetatable({}, { __index = Node })
    local args = { ... }
    if #args == 1 then
        local array = args[1]
        self.array = array
        self.index = 1
        self.value = array[1]
    elseif #args == 2 then
        local lc, wc = unpack(args)
        self.lc = lc
        self.wc = wc
        lc.parent = self
        wc.parent = self
        self.winner = wc.winner and wc.winner or wc
        self.value = lc.winner and lc.winner.value or lc.value
    end
    return self
end

---Advance the value of the node by one
function Node:next()
    if not self.index then
        error("not leaf: " .. vim.inspect(self))
    end
    self.index = self.index + 1
    self.value = self.array[self.index]
end

---Check if the node is root
---@return boolean
function Node:is_root()
    if self.parent then
        return false
    end
    return true
end

---@class Tree
---@field [1] Node
---@field position integer for build
---@field play fun(n1: Node, n2: Node): Node, Node @for replace
local Tree = {}

---Create a new Tree instance
---@param a? table<any, array>[]
---@return Tree
function Tree._init(a)
    local self = setmetatable({}, { __index = Tree })
    for _, v in pairs(a) do
        table.insert(self, Node.init(v))
    end
    self.position = 0
    return self
end

---Take next node
---@return Node
function Tree:take()
    self.position = self.position + 1
    return self[self.position]
end

---Build a new tree
---@param arrays table<any, array>[]
---@param comp fun(a: any, b: any): boolean
---@return Tree
function Tree.build(arrays, comp)
    local tree = Tree._init(arrays)
    local play = Tree._play(comp)

    local function _build(_elements)
        local _tree = Tree._init({})
        while true do
            local el1 = _elements:take()
            local el2 = _elements:take()
            if el2 then
                local lc, wc = play(el1, el2)
                local parent = Node.init(lc, wc)
                table.insert(_tree, parent)
            else
                if el1 then
                    table.insert(_tree, el1)
                end
                break
            end
        end
        return _tree
    end

    while #tree > 1 do
        tree = _build(tree)
    end
    tree.play = Tree._play(comp, true)

    return tree
end

---Comparison functions for nodes
---@param comp fun(a: any, b:any): boolean
---@param replay boolean if true, for replay, otherwise build
---@return fun(n1: Node, n2: Node): Node, Node
function Tree._play(comp, replay)
    if replay then
        return function(new, parent)
            if comp(new.value, parent.value) then
                return parent, new
            end
            return new, parent
        end
    end
    return function(n1, n2)
        if comp(n1.winner and n1.winner.value or n1.value, n2.winner and n2.winner.value or n2.value) then
            return n2, n1
        end
        return n1, n2
    end
end

---Update the tree
---@param node Node updated node
function Tree:replay(node)
    while not node:is_root() do
        local lc, wc = self.play(node.winner or node, node.parent)
        node = node.parent
        node.value = lc.value
        node.winner = wc.winner or wc
    end
end

---Merge k sorted arrays and return a new sorted array
---@param arrays table<any, array>
---@param comp function
local function merge(arrays, comp)
    local ret = {}
    local tree = Tree.build(arrays, comp)
    while true do
        local winner = tree[1].winner
        table.insert(ret, winner.value)
        winner:next()
        if not winner.value then
            winner = winner.parent.lc
            winner.parent = winner.parent.parent
        end
        if winner:is_root() then
            for i = winner.index, #winner.array do
                table.insert(ret, winner.array[i])
            end
            break
        end
        tree:replay(winner)
    end
    return ret
end

return merge
