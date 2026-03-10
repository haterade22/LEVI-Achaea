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
- pattern: ^A vicious wind rises, lashing and flaying at the body of (\w+) to leave \w+ sensitive and raw\.$
  type: 1
- pattern: ^A dreadful pallor overcomes the features of (\w+)\.$
  type: 1
- pattern: ^As you begin to tap your connection with the Elemental Plane of Water, you summon up a freezing wave to deluge (\w+)\.$
  type: 1
- pattern: ^You summon up a flurry of icicles to slash at (\w+) in a shower of freezing daggers\.$
  type: 1
- pattern: ^The might of Elemental Water suffusing you, you tear at the vital fluids which sustain the body of (\w+) with your will alone\.$
  type: 1
- pattern: ^A loud crack emanates from the (.+) of (\w+)\.$
  type: 1
- pattern: ^You bleed off residual power from your connection with the Elemental Plane of Earth, directing it in an unfocussed blast of arcane might at (\w+)\.$
  type: 1
- pattern: ^The might of Elemental Earth coursing through you, you smite (\w+) with the full force of your directed will\.$
  type: 1
- pattern: ^You will that (\w+) should burn, and so \w+ does\.$
  type: 1
- pattern: ^The incandescent might of Elemental Fire filling you, you command (\w+) to burn from within\.$
  type: 1
- pattern: ^The incandescent might of Elemental Fire filling you, you command the suffering (\w+) to burn from within\.$
  type: 1
]]--

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
-- Moderate: Scalded → ablaze
elseif line:find("should burn, and so") then
  local tgt = matches[2]
  if tgt == target then
    tarAffed("burning")
    magi.offense.state.burns = math.min((magi.offense.state.burns or 0) + 1, 5)
    tburns = magi.offense.state.burns
    magi.offense.ptRelay(target .. ": Resonance Fire (scalded>burning, burns:" .. magi.offense.state.burns .. ")")
  end

-- Major: Blistered (not already suffering)
elseif line:find("command (%w+) to burn from within") and not line:find("suffering") then
  local tgt = matches[2]
  if tgt == target then
    tarAffed("blistered")
    magi.offense.ptRelay(target .. ": Resonance Fire (blistered)")
  end

-- Major: Burning (already suffering/blistered)
elseif line:find("command the suffering") then
  local tgt = matches[2]
  if tgt == target then
    tarAffed("burning")
    magi.offense.state.burns = math.min((magi.offense.state.burns or 0) + 1, 5)
    tburns = magi.offense.state.burns
    magi.offense.ptRelay(target .. ": Resonance Fire (burning, burns:" .. magi.offense.state.burns .. ")")
  end
end
