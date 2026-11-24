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
-- v4.7.519: the shield record (`ataxiaBasher.shieldRecord`, blocked/broke per denizen) is listed
-- too, with the shield-safe ones marked; `forget` clears a denizen's record as well.
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
	local key = ataxiaBasher_mobKey and ataxiaBasher_mobKey(rest) or rest
	local rec = type(ataxiaBasher.shieldRecord) == "table" and ataxiaBasher.shieldRecord or {}
	if rest == "all" then
		ataxiaBasher.shieldBreakers = {}
		ataxiaBasher.shieldRecord = {}
		ataxiaEcho("Shield-breaker list and shield record cleared.")
	elseif ataxiaBasher.shieldBreakers[rest] or rec[key] then
		ataxiaBasher.shieldBreakers[rest] = nil
		rec[key] = nil
		ataxiaEcho("Forgot " .. rest .. ".")
	else
		ataxiaEcho("'" .. rest .. "' is not on the shield-breaker list or in the shield record.")
	end
end

if arg ~= "status" and ataxia_saveSettings then ataxia_saveSettings() end

ataxiaEcho("Last stand: " .. ((ataxiaBasher.lastStand == false) and "OFF" or "ON")
	.. ", attacks held until " .. (tonumber(ataxiaBasher.lastStandRelease) or 70) .. "% health.")
local names = {}
for name in pairs(ataxiaBasher.shieldBreakers or {}) do names[#names + 1] = name end
table.sort(names)
cecho("\n  <white>Breaks shields:<reset> " .. ((#names > 0) and table.concat(names, ", ") or "none learned"))
local rows = {}
for key, r in pairs(type(ataxiaBasher.shieldRecord) == "table" and ataxiaBasher.shieldRecord or {}) do
	local safe = ataxiaBasher_shieldSafe and ataxiaBasher_shieldSafe(key)
	rows[#rows + 1] = key .. " " .. (tonumber(r.blocked) or 0) .. "/" .. (tonumber(r.broke) or 0)
		.. (safe and " SAFE" or "")
end
table.sort(rows)
cecho("\n  <white>Shield record (blocked/through):<reset> " .. ((#rows > 0) and table.concat(rows, ", ") or "empty"))
cecho("\n  <DimGrey>bash laststand on|off|release 40-100|forget NAME|forget all\n")
