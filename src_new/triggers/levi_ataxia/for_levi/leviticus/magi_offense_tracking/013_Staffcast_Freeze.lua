--[[mudlet
type: trigger
name: Staffcast Freeze
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
- pattern: ^You point .+ at (\w+) and \w+ screams in pain as \w+ skin begins to freeze and crack\.$
  type: 1
]]--

local tgt = matches[2]
if not tgt or tgt ~= target then return end

tarAffed("horripilation")

magi.offense = magi.offense or {}
if magi.offense.ptRelay then
  magi.offense.ptRelay(target .. ": Staffcast freeze (horripilation)")
end
if magi.offense.debugEcho then
  magi.offense.debugEcho("Staffcast freeze → horripilation")
end
