--[[mudlet
type: trigger
name: Resonance Afflictions
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- Mage
- General
attributes:
  isActive: 'yes'
  isFolder: 'no'
  isTempTrigger: 'no'
  isMultiline: 'no'
  isPerlSlashGOption: 'no'
  isColorizerTrigger: 'no'
  isFilterTrigger: 'no'
  isSoundTrigger: 'no'
  isColorTrigger: 'no'
  isColorTriggerFg: 'no'
  isColorTriggerBg: 'no'
triggerType: 0
conditonLineDelta: 0
mStayOpen: 0
mCommand: ''
packageName: ''
mFgColor: ''
mBgColor: ''
mSoundFile: ''
colorTriggerFgColor: ''
colorTriggerBgColor: ''
patterns:
- pattern: ^(\w+) clutches at \w+ throat as \w+ gasps for breath\.$
  type: 1
- pattern: ^A vicious wind rises, lashing and flaying at the body of (\w+)
  type: 1
- pattern: ^A dreadful pallor overcomes the features of (\w+)\.$
  type: 1
- pattern: ^As you begin to tap your connection with the Elemental Plane of Water, you summon up
  type: 1
- pattern: ^You summon up a flurry of icicles to slash at (\w+) in a shower of freezing daggers\.$
  type: 1
- pattern: ^The might of Elemental Water suffusing you, you tear at the vital fluids
  type: 1
- pattern: ^A loud crack emanates from the (.+) of (\w+)\.$
  type: 1
- pattern: ^You bleed off residual power from your connection with the Elemental Plane of Earth
  type: 1
- pattern: ^The might of Elemental Earth coursing through you, you smite (\w+) with the full force
  type: 1
- pattern: ^You will that (\w+) should burn, and so \w+ does\.$
  type: 1
- pattern: ^The incandescent might of Elemental Fire filling you, you command (\w+) to burn
  type: 1
- pattern: ^The incandescent might of Elemental Fire filling you, you command the suffering (\w+)
  type: 1
]]--

-- THE LONG LINES ARE MATCHED BY THEIR OPENING WORDS. This user's server wraps at 119-124 columns
-- (CLAUDE.md, v4.7.351) and a trigger sees one row at a time, so a pattern that runs past the
-- break never matches. With a seven-letter name, moderate earth (paralysis) is 148 columns and
-- major water (anorexia) 128: their anchored full-line patterns never matched, so the mudslide's
-- "par" and "ano" were never recorded. Minor water (119, frostbite) failed for a longer name.
-- Each long line now matches an early fragment that keeps the plane and level apart, and keeps
-- the name in the fragment where it comes early enough. Where it does not, `withName` reads it
-- from the sentence, on this row or the next (the highlighting/071 idiom), so the name check
-- stays: resonance strikes "the last target of the spell you cast to cause that increase"
-- (Elementalism.wiki:62), and a spell cast at anyone but `target` would otherwise be recorded on
-- our target.
local hit = matches[1]

-- Runs `act(name)` once the sentence gives the name (`namePat`, on the whole sentence). If this
-- row ends before the sentence does, the next row is read too, joined with a space; at most two
-- more rows.
local function withName(namePat, act)
  local function read(text, left)
    local name = text:match(namePat)
    if name then return act(name) end
    if left == 0 or text:match("%.%s*$") then return end
    tempLineTrigger(1, 1, function()
      read((text:gsub("%s+$", "")) .. " " .. (line:gsub("^%s+", "")), left - 1)
    end)
  end
  read(line, 2)
end

-- AIR RESONANCE AFFLICTIONS
-- Minor: Asthma
if hit:find("clutches at .+ throat") then
  local tgt = matches[2]
  if tgt == target then
    tarAffed("asthma")
    magi.offense.ptRelay(target .. ": Resonance Air (asthma)")
    magi.offense.resoEcho("Air", "Asthma", tgt)
  end

-- Moderate: Sensitivity
elseif hit:find("lashing and flaying") then
  local tgt = matches[2]
  if tgt == target then
    tarAffed("sensitivity")
    magi.offense.ptRelay(target .. ": Resonance Air (sensitivity)")
    magi.offense.resoEcho("Air", "Sensitivity", tgt)
  end

-- Major: Healthleech
elseif hit:find("dreadful pallor") then
  local tgt = matches[2]
  if tgt == target then
    tarAffed("healthleech")
    magi.offense.ptRelay(target .. ": Resonance Air (healthleech)")
    magi.offense.resoEcho("Air", "Healthleech", tgt)
  end

-- WATER RESONANCE AFFLICTIONS
-- Minor: Frostbite (the name ends the line)
elseif hit:find("Elemental Plane of Water", 1, true) then
  withName("freezing wave to deluge (%w+)%.", function(tgt)
    if tgt == target then
      tarAffed("frostbite")
      magi.offense.ptRelay(target .. ": Resonance Water (frostbite)")
      magi.offense.resoEcho("Water", "Frostbite", tgt)
    end
  end)

-- Moderate: Stuttering
elseif hit:find("flurry of icicles") then
  local tgt = matches[2]
  if tgt == target then
    tarAffed("stuttering")
    magi.offense.ptRelay(target .. ": Resonance Water (stuttering)")
    magi.offense.resoEcho("Water", "Stuttering", tgt)
  end

-- Major: Anorexia (the name is near the break)
elseif hit:find("tear at the vital fluids") then
  withName("the body of (%w+) with", function(tgt)
    if tgt == target then
      tarAffed("anorexia")
      magi.offense.ptRelay(target .. ": Resonance Water (anorexia)")
      magi.offense.resoEcho("Water", "Anorexia", tgt)
    end
  end)

-- EARTH RESONANCE AFFLICTIONS
-- Minor: Limb break
elseif hit:find("loud crack emanates") then
  -- This pattern captures (limb) of (target)
  local limb = matches[2]
  local tgt = matches[3]
  if tgt == target and limb then
    local limbName = limb:lower():gsub("%s+", "")
    tarAffed("broken" .. limbName)
    magi.offense.ptRelay(target .. ": Resonance Earth (broken " .. limb .. ")")
    magi.offense.resoEcho("Earth", "Broken " .. limb:lower(), tgt)
  end

-- Moderate: Paralysis (the name ends the line, always past the break)
elseif hit:find("residual power from your connection") then
  withName("arcane might at (%w+)%.", function(tgt)
    if tgt == target then
      tarAffed("paralysis")
      magi.offense.ptRelay(target .. ": Resonance Earth (paralysis)")
      magi.offense.resoEcho("Earth", "Paralysis", tgt)
    end
  end)

-- Major: Cracked ribs
elseif hit:find("smite .+ with the full force") then
  local tgt = matches[2]
  if tgt == target then
    tarAffed("crackedribs")
    magi.offense.ptRelay(target .. ": Resonance Earth (cracked ribs)")
    magi.offense.resoEcho("Earth", "Cracked ribs", tgt)
  end

-- FIRE RESONANCE AFFLICTIONS
-- Moderate (fire level 2): Scalded first, then burns if already scalded
elseif hit:find("should burn, and so") then
  local tgt = matches[2]
  if tgt == target then
    if magi.offense.hasAff("scalded") or magi.offense.state.scalded then
      -- Already scalded → increment burns. Open: if the game ALSO prints the fan line here
      -- (022_Increase_Burning), this stack is counted twice (kb/CONFLICTS.md #37).
      magi.offense.state.burns = math.min((magi.offense.state.burns or 0) + 1, 5)
      tburns = magi.offense.state.burns
      tarAffed("burning")
      cecho(" <DimGrey>[<red>" .. tburns .. "/5<DimGrey>]")
      magi.offense.ptRelay(target .. ": Resonance Fire (burning, burns:" .. magi.offense.state.burns .. ")")
      magi.offense.resoEcho("Fire", "Scalded > Burning " .. magi.offense.state.burns .. "/5", tgt)
    else
      -- Not scalded yet → apply scalded + 20s timer
      ataxia_tarAffTimed("scalded")  -- the resonance path never expired it in the tracker
      magi.offense.setScalded()
      magi.offense.ptRelay(target .. ": Resonance Fire (scalded)")
      magi.offense.resoEcho("Fire", "Scalded", tgt)
    end
  end

-- Major (fire level 3): Blistered first (game text without "suffering")
elseif hit:find("command %w+ to burn") and not hit:find("suffering") then
  local tgt = matches[2]
  if tgt == target then
    -- 15 s HAS NO SOURCE: the game's record gives blistered "Cure(s): Time" and no default time
    -- (kb/raw/live/affliction_show/blistered.txt). The shared clock restarts on a repeat and only
    -- erases it from the target it was given to; the bare tempTimer here did neither, so a repeat
    -- blister lapsed on the first one's clock and a target change erased the NEW target's.
    ataxia_tarAffTimed("blistered", 15)
    magi.offense.ptRelay(target .. ": Resonance Fire (blistered)")
    magi.offense.resoEcho("Fire", "Blistered", tgt)
  end

-- Major (fire level 3): Burning (game text with "suffering" = already blistered)
elseif hit:find("command the suffering") then
  local tgt = matches[2]
  if tgt == target then
    magi.offense.state.burns = math.min((magi.offense.state.burns or 0) + 1, 5)
    tburns = magi.offense.state.burns
    tarAffed("burning")
    cecho(" <DimGrey>[<red>" .. tburns .. "/5<DimGrey>]")
    magi.offense.ptRelay(target .. ": Resonance Fire (burning, burns:" .. magi.offense.state.burns .. ")")
    magi.offense.resoEcho("Fire", "Blistered > Burning " .. magi.offense.state.burns .. "/5", tgt)
  end
end
