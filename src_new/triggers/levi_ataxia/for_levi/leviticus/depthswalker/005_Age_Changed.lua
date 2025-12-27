--[[mudlet
type: trigger
name: Age Changed
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
- pattern: ^The effects of your time manipulation fade somewhat, leaving you only aged by (\d+) years.$
  type: 1
- pattern: ^You have now aged yourself by (\d+) years.$
  type: 1
- pattern: ^You are now unnaturally aged by (\d+) years.$
  type: 1
]]--

ataxiaTables.depthswalker.age = tonumber(matches[2])