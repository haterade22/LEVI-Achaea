--[[mudlet
type: trigger
name: Deliverance Starting
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Misc Tracking
- Warnings
- Warnings
- Instakills
- Deliverance
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
- pattern: ^([A-Z][a-z]+) bows (\w+) head in silent prayer\.$
  type: 1
]]--

cecho("\n<white:blue>Deliverance started by <yellow:blue>" .. matches[2] .. "!\n<white:blue>Deliverance started by <yellow:blue>" .. matches[2] .. "!")
ataxia_setWarning(matches[2].." starting deliverance", 2)