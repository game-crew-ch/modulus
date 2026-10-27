AddCSLuaFile()
local PathOps = {}

local _table_insert = table.insert
local _table_concat = table.concat

setfenv(1, PathOps)

function PathOps:__div(value)
    _table_insert(self.components, value)
    return self
end


function PathOps:__tostring()
    return _table_concat(self.components, '/')
end

return PathOps
