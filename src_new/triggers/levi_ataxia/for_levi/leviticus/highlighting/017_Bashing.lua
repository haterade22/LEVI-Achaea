--[[mudlet
type: trigger
name: Bashing
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- Highlighting
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
- pattern: ^With expert precision, you draw Blazing Flames from its scabbard and unleash a vicious slash towards a (.+)\.$
  type: 1
- pattern: ^You slip behind (.+) and garrote (\w+) with your whip.$
  type: 1
]]--

selectString(line,1)
  setBold(true)
  fg("sienna")
  deselect()
  resetFormat()
