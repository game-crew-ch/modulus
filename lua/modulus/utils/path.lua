local OriginalFns = OriginalFns or {}

local _table_insert = table.insert
local _table_concat = table.concat
local _type = type
local _pairs = pairs
local _setmetatable = setmetatable
local _tostring = tostring

local PathOps = {}

function PathOps.__div(self, value)
    _table_insert(self.components, value)
    return self
end


function PathOps.__tostring(self)
    return _table_concat(self.components, '/')
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
        IsValidPath(oldName) and tostring(oldName) or oldName,
        IsValidPath(newName) and tostring(newName) or newName,
        ...
    )
end

local _include = OriginalFns['include'] or include
OriginalFns['include'] = _include
include = function(path, ...)
    return _include(IsValidPath(path) and _tostring(path) or path, ...)
end

return _setmetatable({}, { __div = function(self, value) return _setmetatable({ components = { value }, type = 'Path' }, PathOps) end })
