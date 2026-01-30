--[[mudlet
type: trigger
name: Judgement one
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Misc Tracking
- Warnings
- Warnings
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
conditonLineDelta: 99
mStayOpen: 0
mCommand: ''
packageName: ''
mFgColor: '#ff0000'
mBgColor: '#ffff00'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
patterns:
- pattern: ^(\w+) raises (?:his|her) .+ mace over you to pass judgement on your sins, and it begins to crackle with righteous
    fire\.$
  type: 1
- pattern: ^(\w+) raises .+ mace over you to pass judgement on your sins, and it begins to crackle with righteous fire\.$
  type: 1
]]--

cecho("\n<red>".. string.format("%s started judging you (1/4)!", matches[2]))

ataxia_setWarning(matches[2].." judging you", 2)