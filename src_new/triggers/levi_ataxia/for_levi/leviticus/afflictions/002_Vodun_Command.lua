--[[mudlet
type: trigger
name: Vodun Command
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Class Stuff
- Vodun
- Afflictions
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
- pattern: ^You whisper, .+ to the doll of \w+.$
  type: 1
]]--

vodunCheck = true
tempTimer(0.5, [[ vodunCheck = nil ]])

ataxiaTemp.dollFashions = ataxiaTemp.dollFashions - 1
cecho(" <yellow>(<a_red>"..ataxiaTemp.dollFashions.."<yellow>)")