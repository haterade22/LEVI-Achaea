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
regex: ^bash floor (\d+|off|culling|cull)$
command: ''
packageName: ''
]]--

-- `bash floor <n|off>` -- keep battlerage at or above <n> by spending only the
-- surplus (gear that pays a bonus above a rage threshold keeps paying). Culling
-- reap is never floored. See ataxiaBasher_rageAfford (basher/001).
-- CULLING (v4.7.229). Culling is exempt from the floor by default -- correct for Golden
-- Dragon, where the ability is `reap`, an EXECUTE, and a kill beats any bonus on swings that
-- will never happen. Wrong for the artifact culling blade on e.g. Bard, where it is just a
-- 1505 unblockable hit: firing it at 36 rage drops us under a 40 floor and switches off the
-- damage bonus for roughly a dozen swings, which outweighs the one hit.
if matches[2] == "culling" or matches[2] == "cull" then
	ataxiaBasher.floorCulling = not ataxiaBasher.floorCulling
	if ataxiaBasher.floorCulling then
		ataxiaEcho("Culling now <green>RESPECTS<reset> the rage floor -- it will not spend below it.")
	else
		ataxiaEcho("Culling is <dark_orange>EXEMPT<reset> from the rage floor (default; right for reap/execute).")
	end
	return
end

-- A MANUAL COMMAND ALWAYS WINS OVER THE BERSERKER'S EDGE BOON (v4.7.296). While the boon is up,
-- `ataxiaBasher_berserkersEdgeApply` has pinned `rageFloor` to 100 and saved whatever it replaced
-- in `rageFloorPreBerserkersEdge`, to be restored on the confirmed run end. If the user then
-- types a floor of their own -- including `bash floor off` -- that choice must be the one that
-- survives, not the boon's saved value from before it was claimed. Dropping the saved-for-boon
-- bookkeeping here means the later revert (`ataxiaBasher_berserkersEdgeRevert`) finds nothing to
-- restore and leaves the user's own setting alone. Without this, typing `bash floor off` mid-boon
-- would appear to work immediately and then silently revert to the OLD floor when the run ended.
ataxiaBasher.rageFloorPreBerserkersEdge = nil
ataxiaBasher.rageFloorSavedForBerserkersEdge = nil

if matches[2] == "off" then
	ataxiaBasher.rageFloor = nil
	ataxiaEcho("Rage floor <red>disabled<reset> -- battlerage spends freely again.")
	return
end

-- Clamp: rage caps at 100 and the priciest gated ability costs 54 (rageraze bigRage).
-- Above 46 that ability could never be afforded, and a class whose rotation banks for
-- an unaffordable cast would stop producing battlerage entirely. This clamp is a safety
-- rail for a HUMAN typing a number -- it does not apply to Berserker's Edge, which writes
-- `rageFloor` directly rather than through this alias, because 100 with nothing firing is
-- exactly what that boon wants.
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
