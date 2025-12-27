--[[mudlet
type: trigger
name: Preempt Faded
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Class Stuff
- Depthswalker
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
- pattern: ^You are no longer predicting the movements of (\w+).$
  type: 1
]]--

ataxia_boxEcho("PREEMPT HAS FADED on "..matches[2], "DarkSlateGrey")
ataxiaTables.depthswalker.canPreempt = false
ataxiaTables.depthswalker.usedPreempt = false

tempTimer(11, [[ataxiaTables.depthswalker.canPreempt = true]])