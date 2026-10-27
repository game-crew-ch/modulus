AddCSLuaFile()
local Package = {}

local _type = type
local _string_match = string.match
local _pairs = pairs

setfenv(1, Package)


local function ValidateModuleUniqueID(moduleId) return _type(moduleId) == 'string' and not (_string_match(moduleId, '^%S+$') == nil) end
local function ValidateModuleDependency(moduleDependency) return _type(moduleDependency) == 'string' and not (_string_match(moduleDependency, '^%S+$') == nil) end
local function ValidateModuleDependencies(moduleDependencies)
    if not moduleDependencies then return true end
    if not (_type(moduleDependencies) == 'table') then return end

    for _, dependency in _pairs(moduleDependencies)
    do
        if not ValidateModuleDependency(dependency) then return end
    end

    return true
end

local function ValidateModuleInfo(moduleInfo)
    if not (_type(moduleInfo) == 'table') then return end

    if not ValidateModuleUniqueID(moduleInfo.uid) then return end
    if not ValidateModuleDependencies(moduleInfo.dependencies or {}) then return end

    return true
end


function ParseModuleInfo(jsonDescription)
    if not jsonDescription then return end

    local moduleInfo = jsonDescription['modulus']
    if not (_type(moduleInfo) == 'table') then return end
    if not ValidateModuleInfo(moduleInfo) then return end

    moduleInfo.authors = moduleInfo.authors or {}
    moduleInfo.description = moduleInfo.description or ''
    moduleInfo.dependencies = moduleInfo.dependencies or {}

    return moduleInfo
end


return Package
