-- LEVI-Achaea Loader
-- This file loads all external Lua modules into Mudlet
-- Usage: Create an alias in Mudlet (e.g., "rr") that runs:
--   dofile("C:/Users/mikew/source/repos/Achaea/LEVI-Achaea/src/loader.lua")

local basePath = "C:/Users/mikew/source/repos/Achaea/LEVI-Achaea/src/"

-- Modules to load (in order - dependencies first)
local modules = {
	"core/init.lua",
	"core/events.lua",
	"tracking/afflictions.lua",
	"tracking/balances.lua",
	"combat/offense.lua",
	"basher/basher.lua",
}

-- Track load status
local loaded = 0
local failed = 0

for _, module in ipairs(modules) do
	local path = basePath .. module
	local success, err = pcall(dofile, path)
	if success then
		loaded = loaded + 1
	else
		failed = failed + 1
		cecho("\n<red>Failed to load " .. module .. ": " .. tostring(err))
	end
end

-- Report results
if failed == 0 then
	cecho("\n<green>LEVI system loaded successfully (" .. loaded .. " modules)")
else
	cecho("\n<yellow>LEVI system loaded with errors (" .. loaded .. " ok, " .. failed .. " failed)")
end

-- Raise event for other systems to hook into
raiseEvent("levi system loaded")
