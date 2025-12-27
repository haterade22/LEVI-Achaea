--[[mudlet
type: trigger
name: FishCast
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Fishing
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
- pattern: ^You cock back your arm and smoothly cast your line over the railing into the nearby water. You judge the cast
    at about (\d+) feet\.$
  type: 1
- pattern: ^You cock back your arm and smoothly cast a line into the nearby water. You judge the cast at about (\d+) feet.$
  type: 1
]]--

linelength = tonumber(matches[2])
bashConsoleEcho("fishing", "Cast line out.")