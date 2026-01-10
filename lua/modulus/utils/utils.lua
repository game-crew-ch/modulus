local Package = {}

local Path = include 'modulus/utils/path.lua'

local _file_find = file.Find
local _file_read = file.Read
local _select = select
local _util_JSONToTable = util.JSONToTable

setfenv(1, Package)


function ListAddons()
    return _select(2, _file_find(Path / 'addons' / '*', 'GAME')) or {}
end


function GetAddonJsonFile(self, addon)
    local result = _select(1, _file_find(Path / 'addons' / addon / 'addon.json', 'GAME'))[1]
    return result and (Path / 'addons' / addon / result) or nil
end


function ReadJson(self, path)
    return _util_JSONToTable(_file_read(path, 'GAME'))
end


return Package
