local limb = matches[2]
local tar = matches[3]

if isTargeted(tar) then
  -- Initialize if needed
  if not lb[tar] then lb[tar] = { hits = {} } end
  if not lb[tar].hits then lb[tar].hits = {} end
  lb[tar].hits[limb] = lb[tar].hits[limb] or 0

  -- Assault raises damage level (+100%)
  lb[tar].hits[limb] = lb[tar].hits[limb] + 100

  -- Update tLimbs for limb highlighting
  local shortMap = {
    head = "H", torso = "T",
    ["left leg"] = "LL", ["right leg"] = "RL",
    ["left arm"] = "LA", ["right arm"] = "RA",
  }
  local short = shortMap[limb]
  if short and tLimbs then
    tLimbs[short] = lb[tar].hits[limb]
  end

  -- Track damage/mangle affs based on new damage level
  local limbNoSpace = limb:gsub(" ", "")
  if lb[tar].hits[limb] >= 200 then
    if limb == "head" then
      tarAffed("concussion")
      if applyAffV3 then applyAffV3("concussion") end
    elseif limb == "torso" then
      tarAffed("serioustrauma")
      if applyAffV3 then applyAffV3("serioustrauma") end
    else
      tarAffed("mangled" .. limbNoSpace)
      if applyAffV3 then applyAffV3("mangled" .. limbNoSpace) end
    end
  elseif lb[tar].hits[limb] >= 100 then
    if limb == "head" then
      tarAffed("damagedhead")
      if applyAffV3 then applyAffV3("damagedhead") end
    elseif limb == "torso" then
      tarAffed("mildtrauma")
      if applyAffV3 then applyAffV3("mildtrauma") end
    else
      tarAffed("damaged" .. limbNoSpace)
      if applyAffV3 then applyAffV3("damaged" .. limbNoSpace) end
    end
  end

  -- Torso assault: adds cracked ribs
  if limb == "torso" then
    if not ataxiaTemp.fractures then
      ataxiaTemp.fractures = { skullfractures = 0, wristfractures = 0, torntendons = 0, crackedribs = 0 }
    end
    ataxiaTemp.fractures.crackedribs = (ataxiaTemp.fractures.crackedribs or 0) + 3
  end
end
