--[[mudlet
type: trigger
name: Hypno Seal
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes K-S
- Serpent
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
- pattern: ^You draw (\w+) out of \w+ hypnotic daze, your suggestions indelibly printed on \w+ mind.$
  type: 1
]]--

tAffs.hypnoseal = true
ataxiaTemp.hypnoseal = true
selectString(line, 1)
setBold(true)
bg("violet")
fg("black")
resetFormat()
serpentsuggest = true

ataxia_boxEcho("HYPNOTIZED - SEALED!", "green:white")