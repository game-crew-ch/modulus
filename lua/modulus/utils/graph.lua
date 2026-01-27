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
-- @param visit      callback when a node has been visited
--
-- @return  true if a cycle was detected
function DFS(self, startNode, visit)
    local visited = {}
    local iter
    local visitNode = function(node)
        if visit then visit(node) end
        visited[node] = true
    end

    iter = function(node)
        -- Cycle detected
        if visited[node] then return true end
        visitNode(node)
        local cycle = false
        for _, child in _pairs(self[node] or {})
        do
            cycle = iter(child) or cycle
        end

        return cycle
    end

    return iter(startNode)
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
            -- Cycle has been found, append the call stack to the result list
            if result then _table_insert(cycles, stack) end
        end
    end

    return cycles
end


-- Inverts the direction of all edges in the graph
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

    for node in _pairs(self)
    do
        if not finished[node]
        then
            local stack = {}
            self:DFS(node, function(n)
                if finished[n] then return end

                _table_insert(stack, 1, n)
                finished[n] = true
            end)

            for _, entry in _pairs(stack) do _table_insert(order, entry) end
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
