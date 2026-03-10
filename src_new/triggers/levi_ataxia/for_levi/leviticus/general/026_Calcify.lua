--[[mudlet
type: trigger
name: Calcify
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
- pattern: ^The might of elemental Earth thrumming within your bones, you point an? \w+ staff at (\w+) and an intangible wave of power strikes forth to smite \w+\.$
  type: 1
- pattern: ^A look of pain comes over (\w+) and the bones seem to shift beneath the skin stretched across \w+ skull\.$
  type: 1
- pattern: ^You sense calcification setting in across the torso of (\w+)\.$
  type: 1
- pattern: ^The calcified torso of (\w+) returns to normal\.$
  type: 1
- pattern: ^The calcified skull of (\w+) returns to normal\.$
  type: 1
]]--

local line = matches[1]

-- Scintilla / Emanation Earth hit (from staffcast or emanation)
if line:find("intangible wave of power strikes forth") then
  local tgt = matches[2]
  if tgt == target then
    magi.offense.ptRelay(target .. ": Emanation Earth")
    magi.offense.debugEcho("Emanation Earth hit on " .. target)
  end

-- Calcify skull complete
elseif line:find("bones seem to shift beneath the skin stretched across") then
  local tgt = matches[2]
  if tgt == target then
    magi.offense.state.calcifiedSkull = true
    tarAffed("calcifiedskull")
    magi.offense.ptRelay(target .. ": Calcified Skull!")
    magi.offense.debugEcho("Calcified skull on " .. target)
    -- Also update legacy tracking
    magi.calcifying_head = false
  end

-- Calcify torso
elseif line:find("calcification setting in across the torso") then
  local tgt = matches[2]
  if tgt == target then
    magi.offense.state.calcifiedTorso = true
    tarAffed("calcifiedtorso")
    magi.offense.ptRelay(target .. ": Calcified Torso!")
    magi.offense.debugEcho("Calcified torso on " .. target)
  end

-- Calcify torso fades
elseif line:find("calcified torso .+ returns to normal") then
  local tgt = matches[2]
  if tgt == target then
    magi.offense.state.calcifiedTorso = false
    erAff("calcifiedtorso")
    magi.offense.debugEcho("Calcified torso faded on " .. target)
  end

-- Calcify skull fades
elseif line:find("calcified skull .+ returns to normal") then
  local tgt = matches[2]
  if tgt == target then
    magi.offense.state.calcifiedSkull = false
    erAff("calcifiedskull")
    magi.offense.debugEcho("Calcified skull faded on " .. target)
  end
end
