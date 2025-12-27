--[[mudlet
type: trigger
name: Fashion Number
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Class Stuff
- Vodun
- Probe Doll
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
- pattern: ^The doll looks to have been fashioned (\d+) times.$
  type: 1
]]--

ataxiaTemp.dollFashions = tonumber(matches[2])
deleteLine()
cecho("\n<a_brown>[<purple>Doll<a_brown>]: <a_red>"..ataxiaTemp.dollFashions.."<DimGrey> fashions.")