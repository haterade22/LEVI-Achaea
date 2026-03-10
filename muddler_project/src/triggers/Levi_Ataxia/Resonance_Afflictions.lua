local line = matches[1]

-- AIR RESONANCE AFFLICTIONS
-- Minor: Asthma
if line:find("clutches at .+ throat") then
  local tgt = matches[2]
  if tgt == target then
    tarAffed("asthma")
    magi.offense.ptRelay(target .. ": Resonance Air (asthma)")
  end

-- Moderate: Sensitivity
elseif line:find("lashing and flaying") then
  local tgt = matches[2]
  if tgt == target then
    tarAffed("sensitivity")
    magi.offense.ptRelay(target .. ": Resonance Air (sensitivity)")
  end

-- Major: Healthleech
elseif line:find("dreadful pallor") then
  local tgt = matches[2]
  if tgt == target then
    tarAffed("healthleech")
    magi.offense.ptRelay(target .. ": Resonance Air (healthleech)")
  end

-- WATER RESONANCE AFFLICTIONS
-- Minor: Frostbite
elseif line:find("freezing wave to deluge") then
  local tgt = matches[2]
  if tgt == target then
    tarAffed("frostbite")
    magi.offense.ptRelay(target .. ": Resonance Water (frostbite)")
  end

-- Moderate: Stuttering
elseif line:find("flurry of icicles") then
  local tgt = matches[2]
  if tgt == target then
    tarAffed("stuttering")
    magi.offense.ptRelay(target .. ": Resonance Water (stuttering)")
  end

-- Major: Anorexia
elseif line:find("tear at the vital fluids") then
  local tgt = matches[2]
  if tgt == target then
    tarAffed("anorexia")
    magi.offense.ptRelay(target .. ": Resonance Water (anorexia)")
  end

-- EARTH RESONANCE AFFLICTIONS
-- Minor: Limb break
elseif line:find("loud crack emanates") then
  -- This pattern captures (limb) of (target)
  local limb = matches[2]
  local tgt = matches[3]
  if tgt == target and limb then
    local limbName = limb:lower():gsub("%s+", "")
    tarAffed("broken" .. limbName)
    magi.offense.ptRelay(target .. ": Resonance Earth (broken " .. limb .. ")")
  end

-- Moderate: Paralysis
elseif line:find("residual power from your connection") then
  local tgt = matches[2]
  if tgt == target then
    tarAffed("paralysis")
    magi.offense.ptRelay(target .. ": Resonance Earth (paralysis)")
  end

-- Major: Cracked ribs
elseif line:find("smite .+ with the full force") then
  local tgt = matches[2]
  if tgt == target then
    tarAffed("crackedribs")
    magi.offense.ptRelay(target .. ": Resonance Earth (cracked ribs)")
  end

-- FIRE RESONANCE AFFLICTIONS
-- Moderate (fire level 2): Scalded first, then burns if already scalded
elseif line:find("should burn, and so") then
  local tgt = matches[2]
  if tgt == target then
    if magi.offense.hasAff("scalded") or magi.offense.state.scalded then
      -- Already scalded → increment burns
      magi.offense.state.burns = math.min((magi.offense.state.burns or 0) + 1, 5)
      tburns = magi.offense.state.burns
      tarAffed("burning")
      cecho(" <DimGrey>[<red>" .. tburns .. "/5<DimGrey>]")
      magi.offense.ptRelay(target .. ": Resonance Fire (burning, burns:" .. magi.offense.state.burns .. ")")
    else
      -- Not scalded yet → apply scalded + 20s timer
      tarAffed("scalded")
      magi.offense.setScalded()
      magi.offense.ptRelay(target .. ": Resonance Fire (scalded)")
    end
  end

-- Major (fire level 3): Blistered first (game text without "suffering")
elseif line:find("command (%w+) to burn from within") and not line:find("suffering") then
  local tgt = matches[2]
  if tgt == target then
    tarAffed("blistered")
    tempTimer(15, [[erAff("blistered")]])
    magi.offense.ptRelay(target .. ": Resonance Fire (blistered)")
  end

-- Major (fire level 3): Burning (game text with "suffering" = already blistered)
elseif line:find("command the suffering") then
  local tgt = matches[2]
  if tgt == target then
    magi.offense.state.burns = math.min((magi.offense.state.burns or 0) + 1, 5)
    tburns = magi.offense.state.burns
    tarAffed("burning")
    cecho(" <DimGrey>[<red>" .. tburns .. "/5<DimGrey>]")
    magi.offense.ptRelay(target .. ": Resonance Fire (burning, burns:" .. magi.offense.state.burns .. ")")
  end
end
