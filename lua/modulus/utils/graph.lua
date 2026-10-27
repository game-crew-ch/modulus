AddCSLuaFile()

local _setmetatable = setmetatable
local _setfenv = setfenv
local _pairs = pairs
local _table_insert = table.insert

local Graph = {}
_setfenv(1, Graph)

-- Visits all the node in a graph using Depth-First Search (DFS)
-- @param self       the graph table
-- @param startNode  the node to start DFS from
-- @param visit      callback when a node is first entered (pre-order)
-- @param postVisit  callback when a node is exited (post-order)
--
-- @return  nil if no cycle, last node visited if cycle detected
function DFS(self, startNode, visit, postVisit)
    local visited = {}

    local iter
    local visitNode = function(node)
        if visit then visit(node) end
        visited[node] = true
    end

    iter = function(node, stack)
        -- Already visited in this recursion, cycle detected
        if stack[node] then return node end
        -- Already visited, we can skip
        if visited[node] then return end

        visitNode(node)

        stack[node] = true
        local cycle
        for _, child in _pairs(self[node] or {})
        do
            cycle = iter(child, stack) or cycle
        end
        stack[node] = nil

        if postVisit then postVisit(node) end

        return cycle
    end

    return iter(startNode, {})
end


-- Finds all cycles in a directed graph
-- @param self  the graph table
--
-- @return  a table of cycles found
function FindCycles(self)
    local finished = {}
    local cycles = {}

    for node in _pairs(self)
    do
        if not finished[node]
        then
            local stack = {}
            local result = self:DFS(node, function(n)
                _table_insert(stack, n)
                finished[n] = true
            end)

            if result
            then
                -- Cycle has been found, append the call stack to the result list
                _table_insert(stack, result)
                _table_insert(cycles, stack)
            end
        end
    end

    return cycles
end


-- Inverts the direction of all edges in a graph
-- @param self  the graph object
--
-- @return  the graph with inverted edges
function Invert(self)
    local nodes = {}
    for node, children in _pairs(self)
    do
        for _, child in _pairs(children)
        do
            local edge = nodes[child] or {}
            _table_insert(edge, node)
            nodes[child] = edge
        end
    end

    return _setmetatable(nodes, { __index = Graph })
end


-- Sorts the nodes topologically and returns them.
-- @param self  the graph object
--
-- @return  the list of nodes in topological order
function TopologicalSort(self)
    local order = {}
    local finished = {}

    local function postVisit(n)
        if not finished[n] then
            _table_insert(order, n)
            finished[n] = true
        end
    end

    for node in _pairs(self)
    do
        if not finished[node]
        then
            self:DFS(node, nil, postVisit)
        end
    end

    return order
end


local Package = {}
_setfenv(1, Package)


function FromDependencyTable(dependencies)
    return _setmetatable(dependencies or {}, { __index = Graph })
end


return Package