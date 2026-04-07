AddCSLuaFile()
local Logger = include 'logger.lua'

local Logging = {}

local _debug_getinfo = debug.getinfo
local _setmetatable = setmetatable

setfenv(1, Logging)

-- Loglevels
TRACE = 1
DEBUG = 2
INFO  = 3
WARN  = 4
ERROR = 5

function Create(name, level)
    local service = name or _debug_getinfo(2, 'S').short_src or '???'
    local logger = _setmetatable({ name = service }, { __index = Logger })
    logger:SetLevel(level or INFO)

    return logger
end


return Logging
