local Package = {}

local _setmetatable = setmetatable
local _string_format = string.format
local _os_date = os.date
local _table_insert = table.insert
local _Color = Color
local _ipairs = ipairs
local _MsgC = MsgC
local _unpack = unpack
local _debug_getinfo = debug.getinfo
local _setfenv = setfenv

local Logger = {}
_setfenv(1, Logger)


local COLOR_TIMESTAMP = _Color(0x96, 0x96, 0x96)
local COLOR_INFO = _Color(0x8C, 0xFF, 0x8C)
local COLOR_WARN = _Color(0xFF, 0xD2, 0x64)
local COLOR_ERROR = _Color(0xFF, 0x5A, 0x5A)
local COLOR_DEBUG = _Color(0x78, 0x78, 0xFF)
local COLOR_MODULE = _Color(0x64, 0x64, 0xFF)
local COLOR_TEXT = _Color(0xE6, 0xE6, 0xE6)

local levelColors = {
    ['DEBUG'] = COLOR_DEBUG,
    ['INFO']  = COLOR_INFO,
    ['WARN']  = COLOR_WARN,
    ['ERROR'] = COLOR_ERROR
}


local function FormatLogMessage(level, service, message, ...)
	local formatted = _string_format(message, ...)
	local timeStamp = _os_date('%Y-%m-%dT%H:%M:%S%z')
	local levelString = _string_format('%5s', level)

	return {
		{ Color = COLOR_TIMESTAMP, Text = timeStamp },
		{ Color = levelColors[level], Text = levelString },
		{ Color = COLOR_MODULE, Text = '[' .. service .. ']' },
		{ Color = COLOR_TEXT, Text = formatted }
	}
end


local function PrintLogMessage(message)
	local arguments = {}
	for _, part in _ipairs(message)
	do
		_table_insert(arguments, part.Color)
		_table_insert(arguments, part.Text)
		_table_insert(arguments, '  ')
	end
	arguments[#arguments] = '\n'
	_MsgC(_unpack(arguments))
end


function Debug(self, message, ...) PrintLogMessage(FormatLogMessage('DEBUG', self.name, message, ...)) end
function Info(self, message, ...) PrintLogMessage(FormatLogMessage('INFO', self.name, message, ...)) end
function Warn(self, message, ...) PrintLogMessage(FormatLogMessage('WARN', self.name, message, ...)) end
function Error(self, message, ...) PrintLogMessage(FormatLogMessage('ERROR', self.name, message, ...)) end

_setfenv(1, Package)

function Create(name)
	local service = name or _debug_getinfo(2, 'S').short_src or '???'
	return _setmetatable({ name = service }, { __index = Logger })
end


return _setmetatable({}, { __index = Package })
