AddCSLuaFile()

local modulus = include 'modulus/utils/modulus.lua'
local Graph = include 'modulus/utils/graph.lua'

-- Temporary alias (In future: Modulus will be scoped per module)
Modulus = modulus


local function BuildDependencyGraph(modules)
    local graph = {}

    for moduleName, moduleInfo in pairs(modules)
    do
        graph[moduleName] = moduleInfo:GetDependencies() or {}
    end

    return Graph.FromDependencyTable(graph)
end


modulus:LoadInternalModules()
local Logger = modulus:GetModule('modulus-logging').Create('modulus')


local sep = string.rep('=', 100)
Logger:Info(sep)
Logger:Info('Modulus Initialisation')
Logger:Info(sep)

-- Steps

-- Scan modules (load module info)
-- Check module dependencies and load order
-- Send module info & load order to client
-- Load modules in order (client & server)
hook.Add('Modulus::Internal::LoadModules', 'Modulus::Initialisation', function(loadOrder)

    Logger:Info('Loading modules...')

    hook.Run('Modulus::PreInitialised', Modulus)

    for _, moduleName in pairs(loadOrder)
    do
        local module = modulus:GetModule(moduleName)
        -- Prevent loading of internal modules (e.g. logging)
        if module.loaded then continue end

        hook.Run('Modulus::PreLoadModule', moduleName, module)
        modulus:LoadModule(moduleName)
        hook.Run('Modulus::PostLoadModule', moduleName, module)
        hook.Run('Modulus::ModuleLoaded', moduleName, module)
    end

    hook.Run('Modulus::PostInitialised', Modulus)
end)


if SERVER
then
    Logger:Info('Scanning modules...')

    modulus:ScanModules()
    local modules = modulus:GetModules()
    local graph = BuildDependencyGraph(modules)

    for moduleName, moduleInfo in pairs(modules)
    do
        if not moduleInfo.active
        then
            Logger:Warn('Module %s has been deactivated, reasons: %s', moduleName, table.concat(moduleInfo.reasons, '|') or 'n/a')
        end
    end

    -- Iterate through graph, filter out inactive modules
    for moduleName in pairs(modulus:GetModules())
    do
        if not modulus:GetModule(moduleName).active
        then
            graph[moduleName] = nil
        end
    end

    local loadOrder = graph:TopologicalSort()

    -- Hack: Before sync, we need to 'AddCSLuaFile' every init.lua file
    for _, moduleName in pairs(loadOrder)
    do
        local module = modulus:GetModule(moduleName)
        if module.loaded then continue end
        local initPath = module:GetPath() .. '/init.lua'
        if file.Exists(initPath, 'LUA')
        then
            AddCSLuaFile(initPath)
        end
    end

    modulus:SyncModules(loadOrder)
    timer.Simple(0, function() hook.Call('Modulus::Internal::LoadModules', nil, loadOrder) end)
end

if CLIENT
then
    modulus:SyncModules()
end
