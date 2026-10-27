AddCSLuaFile()
local PathOps = include 'path_ops.lua'

OriginalFns = OriginalFns or {}

local _setmetatable = setmetatable
local _tostring = tostring
local _type = type
local _pairs = pairs

function path(value)
    return _setmetatable({ components = { value }, type = 'Path' }, PathOps)
end


-- Override file function to support Paths
local IsValidPath = function(path) return path and _type(path) == 'table' and path.type == 'Path' end
local function WrapFileFunction(fn)
    local original = OriginalFns['file.' .. fn] or file[fn]
    OriginalFns['file.' .. fn] = original
    file[fn] = function(name, ...) return original(IsValidPath(name) and _tostring(name) or name, ...) end
end

local fileFunctions = { 'Append', 'AsyncRead', 'CreateDir', 'Delete', 'Exists', 'Find', 'IsDir', 'Open', 'Read', 'Size', 'Time', 'Write' }
for _, fn in _pairs(fileFunctions) do WrapFileFunction(fn) end

local _file_rename = OriginalFns['file.Rename'] or file.Rename
OriginalFns['file.Rename'] = _file_rename
file.Rename = function(oldName, newName, ...)
    return _file_rename(
        IsValidPath(oldName) and _tostring(oldName) or oldName,
        IsValidPath(newName) and _tostring(newName) or newName,
        ...
    )
end

local _include = OriginalFns['include'] or include
OriginalFns['include'] = _include
include = function(path, ...)
    return _include(IsValidPath(path) and _tostring(path) or path, ...)
end


return {}
