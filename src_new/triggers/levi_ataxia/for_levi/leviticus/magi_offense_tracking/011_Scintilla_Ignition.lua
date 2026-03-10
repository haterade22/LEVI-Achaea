--[[mudlet
type: trigger
name: Scintilla Ignition
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- Mage
- Magi Offense Tracking
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
- pattern: ^Flames ignite all over the body of (\w+), fanned to intensity in an instant\.$
  type: 1
]]--

local tgt = matches[2]
if not tgt or tgt ~= target then return end

magi.offense = magi.offense or {}
magi.offense.state = magi.offense.state or {}

-- Clear spark state
magi.offense.state.scintillaSpark = false
if magi.offense.state.scintillaTimer then
  killTimer(magi.offense.state.scintillaTimer)
  magi.offense.state.scintillaTimer = nil
end

-- Scintilla ignition causes burning + burns increment
tarAffed("burning")
magi.offense.state.burns = math.min((magi.offense.state.burns or 0) + 1, 5)
tburns = magi.offense.state.burns
selectCurrentLine() fg("red")

if magi.offense.ptRelay then
  magi.offense.ptRelay(target .. ": Scintilla ignition (burning, burns:" .. magi.offense.state.burns .. ")")
end
if magi.offense.debugEcho then
  magi.offense.debugEcho("Scintilla ignition → burning, burns:" .. magi.offense.state.burns)
end

-- Burns counter display
if magi.offense.state.burns > 0 then
  cecho(" <DimGrey>[<red>" .. magi.offense.state.burns .. "/5<DimGrey>]")
end
