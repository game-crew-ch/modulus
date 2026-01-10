local Package = {}

local _pairs = pairs
local _table_insert = table.insert

setfenv(1, Package)


-- Visits all the node in a graph using Depth-First Search (DFS)
-- @param graph  the graph table
-- @param node   the node to start DFS from
-- @param visit  callback when a node has been visited
--
-- @return  true if a cycle was detected
function DFS(graph, node, visit)
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
        for _, child in _pairs(graph[node] or {})
        do
            cycle = iter(child) or cycle
        end

        return cycle
    end

    return iter(node)
end


-- Finds all cycles in a directed graph
-- @param graph  the graph table
--
-- @return  a table of cycles found
function FindCycles(graph)
    local finished = {}
    local cycles = {}

    for node in _pairs(graph)
    do
        if not finished[node]
        then
            local stack = {}
            local result = DFS(graph, node, function(node)
                _table_insert(stack, node)
                finished[node] = true
            end)
            -- Cycle has been found, append the call stack to the result list
            if result then _table_insert(cycles, stack) end
        end
    end

    return cycles
end


return Package
