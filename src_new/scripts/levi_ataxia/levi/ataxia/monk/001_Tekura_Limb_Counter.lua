--[[mudlet
type: script
name: Tekura Limb Counter
hierarchy:
- Levi_Ataxia
- LEVI
- Ataxia
- Ataxia
- Combat
- Offensive Things
- Monk
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

function tekura_addDamage(attack, limb)
  local limbs = {
    ["head"] = "H",
    ["torso"] = "T",
    ["left leg"] = "LL",
    ["right leg"] = "RL",
    ["left arm"] = "LA",
    ["right arm"] = "RA",
  }
  local l = limbs[limb]

  if not tekura_limbDamage[attack] then
    ataxiaEcho("Formula for "..attack.." not calculated?")
  else
    local x = tekura_limbDamage[attack]
  
    local oldDmg = tLimbs[l]
    tLimbs[l] = tLimbs[l] + x
    -- Per-hit cap: single hit can't push past 100%, subsequent hits stack to 200%
    if oldDmg < 100 and tLimbs[l] > 100 then tLimbs[l] = 100 end
    tLimbs[l] = math.min(tLimbs[l], 200)

    if tLimbs[l] > 99.99 then
      cecho("\n<red> -= "..limb.." broke! =-")
      if limb == "head" then tAffs.stupidity = true end
			target_limbBroke(limb)
      targetLimbs_updateTimers(limb)
    else
			cecho("<NavajoWhite> [@ <purple>"..tLimbs[l].."%<NavajoWhite>]")
      targetLimbs_updateTimers(limb)
    end
  end
end
