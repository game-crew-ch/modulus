AddCSLuaFile()
local Logger = {}

local _Color = Color
local _string_format = string.format
local _os_date = os.date
local _table_insert = table.insert
local _ipairs = ipairs
local _MsgC = MsgC
local _unpack = unpack

setfenv(1, Logger)


local COLOR_TRACE = _Color(0xA0, 0xA0, 0xA0)
local COLOR_DEBUG = _Color(0x78, 0x78, 0xFF)
local COLOR_INFO = _Color(0x8C, 0xFF, 0x8C)
local COLOR_WARN = _Color(0xFF, 0xD2, 0x64)
local COLOR_ERROR = _Color(0xFF, 0x5A, 0x5A)

local COLOR_TIMESTAMP = _Color(0x96, 0x96, 0x96)
local COLOR_MODULE = _Color(0x64, 0x64, 0xFF)
local COLOR_TEXT = _Color(0xE6, 0xE6, 0xE6)

local COLOR_FOR_LEVEL = {
    TRACE = COLOR_TRACE,
    DEBUG = COLOR_DEBUG,
    INFO  = COLOR_INFO,
    WARN  = COLOR_WARN,
    ERROR = COLOR_ERROR
}


local function FormatLogMessage(level, service, message, ...)
	local formatted = _string_format(message or '', ...)
	local timeStamp = _os_date('%Y-%m-%dT%H:%M:%S%z')
	local levelString = _string_format('%5s', level)

	return {
		{ Color = COLOR_TIMESTAMP, Text = timeStamp },
		{ Color = COLOR_FOR_LEVEL[level], Text = levelString },
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


local function Noop() end

local function LogTrace(self, message, ...) PrintLogMessage(FormatLogMessage('TRACE', self.name, message, ...)) end
local function LogDebug(self, message, ...) PrintLogMessage(FormatLogMessage('DEBUG', self.name, message, ...)) end
local function  LogInfo(self, message, ...) PrintLogMessage(FormatLogMessage( 'INFO', self.name, message, ...)) end
local function  LogWarn(self, message, ...) PrintLogMessage(FormatLogMessage( 'WARN', self.name, message, ...)) end
local function LogError(self, message, ...) PrintLogMessage(FormatLogMessage('ERROR', self.name, message, ...)) end

function SetLevel(self, level)
    self.level = level

    self.Trace = self.level <= 1 and LogTrace or Noop
    self.Debug = self.level <= 2 and LogDebug or Noop
    self.Info  = self.level <= 3 and LogInfo  or Noop
    self.Warn  = self.level <= 4 and LogWarn  or Noop
    self.Error = self.level <= 5 and LogError or Noop
end


return Logger
