--[[mudlet
type: trigger
name: Meteorite
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
- pattern: ^A meteorite smashes through the translucent shield surrounding (\w+) in an explosion of translucent shards and snapping bones\.$
  type: 1
- pattern: ^A flaming meteorite smashes through the magical shield surrounding (\w+) in an explosion of translucent shards and fire\.$
  type: 1
- pattern: ^A frozen meteorite smashes through the magical shield surrounding (\w+) in an explosion of translucent shards and chill\.$
  type: 1
- pattern: You sense your arcane work unravel as no wards are found to shatter\.
  type: 0
]]--

local line = matches[1]

-- Flaming meteorite — shield stripped + burning applied
if line:find("flaming meteorite") then
  local tgt = matches[2]
  if tgt == target then
    erAff("shield")
    tarAffed("burning")
    magi.offense.state.burns = math.min((magi.offense.state.burns or 0) + 1, 5)
    tburns = magi.offense.state.burns
    magi.offense.ptRelay(target .. ": Meteorite Flaming (shield stripped + burning)")
    magi.offense.debugEcho("Meteorite flaming → shield stripped + burns:" .. magi.offense.state.burns)
    raiseEvent("offense update")
  end

-- Frozen meteorite — shield stripped + frozen
elseif line:find("frozen meteorite") then
  local tgt = matches[2]
  if tgt == target then
    erAff("shield")
    magi.offense.state.frozen = true
    tarAffed("frozen")
    magi.offense.ptRelay(target .. ": Meteorite Frozen (shield stripped + frozen)")
    magi.offense.debugEcho("Meteorite frozen → shield stripped + frozen")
    raiseEvent("offense update")
  end

-- Pure/standard meteorite — shield stripped only
elseif line:find("snapping bones") then
  local tgt = matches[2]
  if tgt == target then
    erAff("shield")
    magi.offense.ptRelay(target .. ": Meteorite Pure (shield stripped)")
    magi.offense.debugEcho("Meteorite pure → shield stripped")
    raiseEvent("offense update")
  end

-- No wards found (target had no shield — rare edge case)
elseif line:find("no wards are found") then
  magi.offense.debugEcho("Meteorite: no shield found on target")
  erAff("shield")
  raiseEvent("offense update")
end
