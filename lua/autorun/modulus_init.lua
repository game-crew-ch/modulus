-- Just a simple failsafe
if not SERVER then return end

OriginalFns = {}

-- Ensure Modulus is initialised after any other addons, unless they use the same ugly hack
timer.Simple(0, function()
	include('modulus/init.lua')
end)
