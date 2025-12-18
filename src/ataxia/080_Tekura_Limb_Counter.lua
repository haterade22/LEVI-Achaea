-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Ataxia-DownloadThis > Ataxia > Combat > Offensive Things > Monk > Tekura Limb Counter

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
  
    tLimbs[l] = tLimbs[l] + x
    
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
