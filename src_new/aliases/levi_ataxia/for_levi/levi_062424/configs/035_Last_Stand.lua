--[[mudlet
type: alias
name: Last Stand
hierarchy:
- Levi_Ataxia
- For Levi
- levi_062424
- Configs
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
regex: ^bash laststand(?:\s+(\w+))?(?:\s+(.+))?$
]]--

-- `bash laststand [on|off|release <pct>|forget <denizen>|forget all]` (basher/001, v4.7.486).
-- In a no-flee area with no retreat left and critical health, the basher shields and holds its
-- attacks until health is back at the release percentage. Denizens that broke the shield are
-- listed here; `forget` takes one off the list.
local arg = (matches[2] or "status"):lower()
local rest = matches[3] and matches[3]:lower() or nil

if arg == "on" then
	ataxiaBasher.lastStand = true
	ataxiaEcho("Last stand ON: no way out at critical health = shield and heal.")
elseif arg == "off" then
	ataxiaBasher.lastStand = false
	ataxiaEcho("Last stand OFF: no way out = keep attacking.")
elseif arg == "release" and tonumber(rest) then
	local n = math.max(40, math.min(100, math.floor(tonumber(rest))))
	ataxiaBasher.lastStandRelease = n
	ataxiaEcho("Last stand holds the attacks until " .. n .. "% health.")
elseif arg == "forget" and rest then
	ataxiaBasher.shieldBreakers = ataxiaBasher.shieldBreakers or {}
	if rest == "all" then
		ataxiaBasher.shieldBreakers = {}
		ataxiaEcho("Shield-breaker list cleared.")
	elseif ataxiaBasher.shieldBreakers[rest] then
		ataxiaBasher.shieldBreakers[rest] = nil
		ataxiaEcho("Forgot " .. rest .. ".")
	else
		ataxiaEcho("'" .. rest .. "' is not on the shield-breaker list.")
	end
end

if arg ~= "status" and ataxia_saveSettings then ataxia_saveSettings() end

ataxiaEcho("Last stand: " .. ((ataxiaBasher.lastStand == false) and "OFF" or "ON")
	.. ", attacks held until " .. (tonumber(ataxiaBasher.lastStandRelease) or 70) .. "% health.")
local names = {}
for name in pairs(ataxiaBasher.shieldBreakers or {}) do names[#names + 1] = name end
table.sort(names)
cecho("\n  <white>Breaks shields:<reset> " .. ((#names > 0) and table.concat(names, ", ") or "none learned"))
cecho("\n  <DimGrey>bash laststand on|off|release 40-100|forget NAME|forget all\n")
