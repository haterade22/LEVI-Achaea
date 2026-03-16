--[[mudlet
type: script
name: Psion Limb Tracking
hierarchy:
- Levi_Ataxia
- LEVI
- Ataxia
- Ataxia
- Combat
- Offensive Things
- Limb Management
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

function psion_hitLimb(limb)
	local toLimb = {
		["head"] = "H",
		["torso"] = "T",
		["right leg"] = "RL",
		["left leg"] = "LL",
		["right arm"] = "RA",
		["left arm"] = "LA",
	}
	local lco = toLimb[limb]
	
	local oldDmg = tLimbs[lco]
	if lco == "RL" or lco == "LL" then
		tLimbs[lco] = tLimbs[lco] + 20
	else
		tLimbs[lco] = tLimbs[lco] + 25
	end
	-- Per-hit cap: single hit can't push past 100%, subsequent hits stack to 200%
	if oldDmg < 100 and tLimbs[lco] > 100 then tLimbs[lco] = 100 end
	tLimbs[lco] = math.min(tLimbs[lco], 200)

	if tLimbs[lco] >= 98 then
		cecho("\n<a_red> >> [ <a_darkcyan>"..target:upper().."'S "..limb:upper().." HAS BEEN BROKEN <a_red> ] <<")
		target_limbBroke(limb)
		if limb == "head" then
			tAffs.stupidity = true
		end
	end
	targetLimbs_updateTimers(limb)
end