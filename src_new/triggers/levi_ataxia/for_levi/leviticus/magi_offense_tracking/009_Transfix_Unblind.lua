--[[mudlet
type: trigger
name: Transfix Unblind
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
- pattern: ^You weave fire and air together to transfix (\w+), but succeed only in curing
  type: 1
]]--

local tgt = matches[2]
if not tgt or tgt ~= target then return end

erAff("blindness")
magi.offense = magi.offense or {}
if magi.offense.ptRelay then
  magi.offense.ptRelay(target .. ": Transfix failed (cured blindness)")
end
if magi.offense.debugEcho then
  magi.offense.debugEcho("Transfix unblind -> erAff blindness")
end
