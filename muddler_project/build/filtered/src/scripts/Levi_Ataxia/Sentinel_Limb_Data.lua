--Currently this is only for level 3.

function sentinel_setBreakpoint(maxhp)
  local spearDmg = linearFit(maxhp)
  local tripDmg = spearDmg/2
  local axeDmg = math.round(.166*maxhp+412, 0)

  axeDmg = (axeDmg/maxhp)*100
  axeDmg = tonumber( string.format("%2.2f", axeDmg) )
  spearDmg = tonumber( string.format("%2.2f", spearDmg) )
  tripDmg = tonumber( string.format("%2.2f", tripDmg) )

  ataxiaTemp.sentinelDamage = {
    spear = spearDmg,
    trip = tripDmg,
    axe = axeDmg
  }
  
end

function sentinel_hitLimb(attack, limb)
  local limbs = {
    ["head"] = "H",
    ["torso"] = "T",
    ["left leg"] = "LL",
    ["right leg"] = "RL",
    ["left arm"] = "LA",
    ["right arm"] = "RA",
  }
  local l = limbs[limb]
  local x = ataxiaTemp.sentinelDamage[attack]
  
  tLimbs[l] = tLimbs[l] + x
    
  if tLimbs[l] > 99.99 then
    cecho("\n<red> -= "..limb.." broke! =-")
    if limb == "head" then tAffs.stupidity = true end
    target_limbBroke(limb)
    targetLimbs_updateTimers(limb)
  else
    cecho("<NavajoWhite> [ @"..tLimbs[l].."%<NavajoWhite>]\n")
    targetLimbs_updateTimers(limb)
  end
end