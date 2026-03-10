--[[mudlet
type: trigger
name: Staffcast Lightning
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
- pattern: ^You point .+ at (\w+), and cause a bolt of lightning to cascade out and roar screaming into \w+\.$
  type: 1
]]--

local tgt = matches[2]
if not tgt or tgt ~= target then return end

-- Staffcast lightning delivers stupidity (handled by 009_Transfix_Stupidity already)
-- This trigger tracks the cast itself for relay purposes
magi.offense = magi.offense or {}
if magi.offense.ptRelay then
  magi.offense.ptRelay(target .. ": Staffcast lightning")
end
if magi.offense.debugEcho then
  magi.offense.debugEcho("Staffcast lightning hit")
end
