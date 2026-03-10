--[[mudlet
type: trigger
name: Deepfreeze
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
- pattern: You drain the heat from the air around your enemies
  type: 3
]]--

-- Deepfreeze is AoE — applies frozen to current target if in same room
if target and target ~= "" then
  tarAffed("frozen")
  selectCurrentLine() fg("cyan")

  magi.offense = magi.offense or {}
  if magi.offense.ptRelay then
    magi.offense.ptRelay(target .. ": Deepfreeze (frozen)")
  end
  if magi.offense.debugEcho then
    magi.offense.debugEcho("Deepfreeze → frozen on " .. target)
  end
end
