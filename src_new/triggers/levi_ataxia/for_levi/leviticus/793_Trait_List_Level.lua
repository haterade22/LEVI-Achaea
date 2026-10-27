--[[mudlet
type: trigger
name: Trait List Level
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
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
mFgColor: '#ff0000'
mBgColor: '#ffff00'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
patterns:
- pattern: ^Level \d+:\s+(.+?)\s*$
  type: 1
]]--

-- TRAIT LIST KNOWN, one trait row: "Level 20: Nimble". Read only inside the window the Racial row
-- (792) opens, so a "Level N:" row of any other output is not a trait (misc_scripts/031).
if ataxia_traitLevel then ataxia_traitLevel(matches[2]) end
