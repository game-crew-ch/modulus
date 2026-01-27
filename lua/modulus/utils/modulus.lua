AddCSLuaFile()
local Package = {}

local Module = include 'modulus/utils/module.lua'
local ModuleInfo = include 'modulus/utils/module-info.lua'
local Utils = include 'modulus/utils/utils.lua'
local Graph = include 'modulus/utils/graph.lua'

local _hook_Call = hook.Call
local _CLIENT = CLIENT
local _SERVER = SERVER
local _pairs = pairs
local _table_insert = table.insert
local _table_concat = table.concat
local _string_format = string.format
local _file_Find = file.Find
local _select = select
local _include = include
local _setmetatable = setmetatable
local _getmetatable = getmetatable
local _file_Read = file.Read
local _file_Exists = file.Exists
local _net_Receive = net.Receive
local _net_ReadTable = net.ReadTable
local _net_Start = net.Start
local _net_WriteTable = net.WriteTable
local _util_AddNetworkString = util.AddNetworkString
local _net_Broadcast = net.Broadcast

setfenv(1, Package)


local modules = {}


local function BuildDependencyGraph(modules)
    local graph = {}

    for moduleName, module in _pairs(modules)
    do
        graph[moduleName] = module:GetDependencies()
    end

    return Graph.FromDependencyTable(graph)
end


local function FindMissingDependencies(graph)
    local missingDependencies = {}

    for moduleName, dependencies in _pairs(graph)
    do
        for _, dependency in _pairs(dependencies)
        do
            if not graph[dependency]
            then
                local missingDependency = missingDependencies[moduleName] or {}
                _table_insert(missingDependency, dependency)
                missingDependencies[moduleName] = missingDependency
            end
        end
    end

    return missingDependencies
end


local function FindModules()
    local result = {}
    for _, addon in _pairs(Utils:ListAddons())
    do
        local addonJsonFile = Utils:GetAddonJsonFile(addon)
        if not addonJsonFile then continue end

        local addonJson = Utils:ReadJson(addonJsonFile)
        local moduleInfo = ModuleInfo.ParseModuleInfo(addonJson)
        if not moduleInfo then continue end
        moduleInfo.path = addon
        local moduleUniqueId = moduleInfo.uid
        result[moduleUniqueId] = Module.FromModuleInfo(moduleInfo)
    end
    return result
end


function SyncModules(self, loadOrder)
    if _CLIENT
    then
        _net_Receive('Modulus::SyncModules', function()
            -- TODO k4su 27/01/2026: Optimize by only receiving necessary data
            local rxModules = _net_ReadTable()
            local rxLoadOrder = _net_ReadTable()

            for moduleName, module in _pairs(rxModules)
            do
                if not modules[moduleName]
                then
                    modules[moduleName] = Module.FromModuleInfo(module.info)
                end
            end

            _hook_Call('Modulus::Internal::LoadModules', nil, rxLoadOrder)
        end)
    end

    if _SERVER
    then
        _util_AddNetworkString('Modulus::SyncModules')
        _net_Start('Modulus::SyncModules')
        -- TODO k4su 27/01/2026: Optimize by only sending necessary data
        _net_WriteTable(modules)
        _net_WriteTable(loadOrder or {})
        _net_Broadcast()
    end
end


function ScanModules(self)
    for moduleName, module in _pairs(FindModules())
    do
        modules[moduleName] = module
    end

    local graph = BuildDependencyGraph(modules)

    -- Deactivate all modules which have missing dependencies
    do
        local missingDependencies = FindMissingDependencies(graph)
        for moduleName, dependencies in _pairs(missingDependencies)
        do
            modules[moduleName]:Deactivate(_string_format('The following dependencies are missing: %s', _table_concat(dependencies, ', ')))
        end
    end

    -- Deactivate all modules which have cyclic dependencies
    do
        local cycles = graph:FindCycles()
        local cyclicModules = {}
        for _, cycle in _pairs(cycles)
        do
            local cycleStr = _table_concat(cycle, ' -> ')
            for _, moduleName in _pairs(cycle)
            do
                cyclicModules[moduleName] = cycleStr
            end
        end

        for moduleName, cycle in _pairs(cyclicModules)
        do
            local module = modules[moduleName]
            if module.active
            then
                module.active = false
                module.reason = 'Cyclic dependency: ' .. cycle
            end
        end
    end

    -- Deactivate all modules which have inactive dependencies
    do
        local dependents = {}
        -- Build inverse dependency graph
        for moduleName, moduleInfo in _pairs(modules)
        do
            if not moduleInfo.active then continue end

            for _, dependency in _pairs(moduleInfo:GetDependencies() or {})
            do
                local dependentList = dependents[dependency] or {}
                _table_insert(dependentList, moduleName)
                dependents[dependency] = dependentList
            end
        end

        -- Deactivate all modules which have inactive dependencies
        for moduleName in _pairs(dependents)
        do
            if not modules[moduleName].active
            then
                Graph.DFS(dependents, moduleName, function(node)
                    if modules[node] and modules[node].active
                    then
                        modules[node]:Deactivate('Transitive dependency ' .. moduleName .. ' is inactive')
                    end
                end)
            end
        end
    end
end


local function LoadInternalModule(name)
    local moduleName = 'modulus-' .. name
    local moduleFile = 'modulus/modules/' .. name .. '/module.lua'
    local content = _include(moduleFile)
    local module = Module.FromModuleInfo({
        uid = moduleName,
        authors = {'Modulus Dev Team'},
        dependencies = {},
        description = 'Internal module'
    }, true)

    local originalMT = _getmetatable(module)
    return moduleName, _setmetatable(module, { __index = function(_, key)
        local val = content[key]
        if val ~= nil then return val end
        return originalMT.__index[key]
    end })
end


function LoadInternalModules()
    for _, name in _pairs(_select(2, _file_Find('modulus/modules/*' , 'LUA')))
    do
        local moduleName, module = LoadInternalModule(name)
        modules[moduleName] = module
    end
end


function LoadModule(self, moduleName)
    local module = self:GetModule(moduleName)
    if not module then return end

    local initFile = module:GetPath() .. '/init.lua'if not _file_Exists(initFile, 'LUA')
    then
        return false
    end

    if _file_Read(initFile, 'LUA') == ''
    then
        return false
    end

    local content = _include(initFile) or {}
    local originalMT = _getmetatable(module)
    modules[moduleName] = _setmetatable(module, { __index = function(_, key)
        local val = content[key]
        if val ~= nil then return val end
        return originalMT.__index[key]
    end })
end


function GetModules() return modules end
function GetModule(_, name) return modules[name] end


return Package
