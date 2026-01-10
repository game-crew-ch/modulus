Modulus = include 'modulus/utils/modulus.lua'

local Path = include 'modulus/utils/path.lua'
local Graph = include 'modulus/utils/graph.lua'
local Module = include 'modulus/utils/module.lua'

local LoggingModule = Module.FromModuleInfo({
        uid = 'modulus-logging',
        authors = {'K4su'},
        dependencies = {},
        description = 'Logging framework'
}, true)

local Logger = include 'modulus/utils/logger.lua'
local Original = getmetatable(LoggingModule)
local Logging = setmetatable(LoggingModule, { __index = function(tbl, key)
    local val = Logger[key]
    if val ~= nil then return val end
    return Original.__index[key]
end })

local Log = Logging.Create('modulus')


local function BuildDependencyGraph(modules)
    local graph = {}

    for moduleName, moduleInfo in pairs(modules)
    do
        graph[moduleName] = moduleInfo:GetDependencies() or {}
    end

    return graph
end


local sep = string.rep('=', 100)
Log:Info(sep)
Log:Info('Modulus Initialisation')
Log:Info(sep)


concommand.Remove('modulus')
concommand.Add('modulus', function(ply, cmd, args)
    if not (ply == NULL) then return end

    local subCommand = args[1]
    if subCommand == 'scan'
    then
        Log:Info('Scanning for modules...')
        Modulus:ScanModules()
    end
end)



Log:Info('Scanning modules...')
Modulus:ScanModules()
Modulus.modules['modulus-logging'] = Logging
-- setmetatable(Modulus.modules['modulus-logging'], { __index = table.concat(Logger, getmetatable(Modulus.modules['modulus-logging'])) })

local graph = BuildDependencyGraph(Modulus.modules)


for moduleName, moduleInfo in pairs(Modulus.modules)
do
    if not moduleInfo.active
    then
        Log:Warn('Module %s has been deactivated, reasons: %s', moduleName, table.concat(moduleInfo.reasons, '|') or 'n/a')
    end
end


-- Iterate through graph, filter out inactive modules
for moduleName in pairs(Modulus.modules)
do
    if not Modulus.modules[moduleName].active
    then
        graph[moduleName] = nil
    end
end

local function TopologicalSort(graph)
    local order = {}
    local finished = {}

    for node in pairs(graph)
    do
        if not finished[node]
        then
            local stack = {}
            Graph.DFS(graph, node, function(node)
                if finished[node] then return end

                table.insert(stack, 1, node)
                finished[node] = true
            end)
            for _, entry in pairs(stack) do table.insert(order, entry) end
        end
    end

    return order
end

local loadOrder = TopologicalSort(graph)

local LoadModule = function(moduleName)
    local module = Modulus.modules[moduleName]
    if not module then return end

    local initFile = Path / module:GetPath() / 'init.lua'
    if not file.Exists(initFile, 'LUA')
    then
        Log:Warn('Module %s is missing init.lua file', moduleName)
        return false
    end

    if file.Read(initFile, 'LUA') == ''
    then
        Log:Warn('Can not include empty init.lua file for module %s', moduleName)
        return false
    end

    return include(initFile)
end

hook.Run('Modulus::PreInitialised', Modulus)

for _, moduleName in pairs(loadOrder)
do
    local module = Modulus.modules[moduleName]
    -- Prevent loading of internal modules (e.g. logging)
    if module.loaded then continue end

    hook.Run('Modulus::PreLoadModule', moduleName, module)
    LoadModule(moduleName)
    hook.Run('Modulus::PostLoadModule', moduleName, module)
end

hook.Run('Modulus::PostInitialised', Modulus)
