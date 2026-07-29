--[[mudlet
type: alias
name: Rage Floor
hierarchy:
- Levi_Ataxia
- Ataxia
- Basher
- Configs
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^bash floor (\d+|off)$
command: ''
packageName: ''
]]--

-- `bash floor <n|off>` -- keep battlerage at or above <n> by spending only the
-- surplus (gear that pays a bonus above a rage threshold keeps paying). Culling
-- reap is never floored. See ataxiaBasher_rageAfford (basher/001).
if matches[2] == "off" then
	ataxiaBasher.rageFloor = nil
	ataxiaEcho("Rage floor <red>disabled<reset> -- battlerage spends freely again.")
	return
end

-- Clamp: rage caps at 100 and the priciest gated ability costs 54 (rageraze bigRage).
-- Above 46 that ability could never be afforded, and a class whose rotation banks for
-- an unaffordable cast would stop producing battlerage entirely.
local MAX_FLOOR = 46
local n = tonumber(matches[2])
if n > MAX_FLOOR then
	ataxiaEcho("Rage floor <dark_orange>clamped to "..MAX_FLOOR.."<reset> (asked for "..n
		.."; above that the priciest battlerage -- 54 rage under rageraze -- could never fire).")
	n = MAX_FLOOR
end

ataxiaBasher.rageFloor = (n > 0) and n or nil
if ataxiaBasher.rageFloor then
	ataxiaEcho("Rage floor <green>"..n.."<reset> -- battlerage only spends the surplus above "..n..".")
else
	ataxiaEcho("Rage floor <red>disabled<reset> -- battlerage spends freely again.")
end
