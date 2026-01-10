local Package = {}

local _pairs = pairs
local _table_insert = table.insert
local _table_concat = table.concat
local _string_format = string.format

local Module = include 'modulus/utils/module.lua'
local ModuleInfo = include 'modulus/utils/module-info.lua'
local Utils = include 'modulus/utils/utils.lua'
local Graph = include 'modulus/utils/graph.lua'

setfenv(1, Package)


local function BuildDependencyGraph(modules)
    local graph = {}

    for moduleName, module in _pairs(modules)
    do
        graph[moduleName] = module:GetDependencies()
    end

    return graph
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


function ScanModules(self)
    self.modules = FindModules()

    local graph = BuildDependencyGraph(self.modules)

    -- Deactivate all modules which have missing dependencies
    do
        local missingDependencies = FindMissingDependencies(graph)
        for moduleName, dependencies in _pairs(missingDependencies)
        do
            self.modules[moduleName]:Deactivate(_string_format('The following dependencies are missing: %s', _table_concat(dependencies, ', ')))
        end
    end

    -- Deactivate all modules which have cyclic dependencies
    do
        local cycles = Graph.FindCycles(graph)
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
            local module = Modulus.modules[moduleName]
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
        for moduleName, moduleInfo in _pairs(self.modules)
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
            if not self.modules[moduleName].active
            then
                Graph.DFS(dependents, moduleName, function(node)
                    if self.modules[node] and self.modules[node].active
                    then
                        self.modules[node]:Deactivate('Transitive dependency ' .. moduleName .. ' is inactive')
                    end
                end)
            end
        end
    end
end


function GetModules(self) return self.modules end


return Package
