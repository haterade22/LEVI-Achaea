-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Ataxia-DownloadThis > Ataxia > Combat > Offensive Things > Limb Management > Sylvan Limbcounting

function sylvan_setBreakpoint(maxhp)
  local breakIn = 0
  if maxhp >= 7000 then
    breakIn = 4.5
  elseif maxhp <= 3500 then
    breakIn = 3
  else
    breakIn = 4
  end
  
  ataxiaTemp.sylvanRend = tonumber( string.format("%2.2f", 100/breakIn) )
  
end

function sylvan_hitLimb(limb)
  local limbs = {
    ["head"] = "H",
    ["torso"] = "T",
    ["left leg"] = "LL",
    ["right leg"] = "RL",
    ["left arm"] = "LA",
    ["right arm"] = "RA",
  }
  local l = limbs[limb]
  local x = (haveAff("vinewreathe") and ataxiaTemp.sylvanRend/2 or ataxiaTemp.sylvanRend)
  
  tLimbs[l] = tLimbs[l] + x
    
  if tLimbs[l] > 99 then
    cecho("\n<red> -= "..limb.." broke! =-")
    if limb == "head" then tAffs.stupidity = true end
    target_limbBroke(limb)
  end
  targetLimbs_updateTimers(limb)
end

function sylvan_propagateAff()
  local list = {
    kelp = "healthleech",
    bellwort = "weariness",
    valerian = "slickness",
    lobelia = "vertigo",
    elm = "dizziness",
    goldenseal = "epilepsy",
    hawthorn = "sensitivity",
  }
  local arm = ataxiaTemp.currentProps.arms
  if list[arm] then
    return list[arm]
  else
    return false
  end
end