--[[mudlet
type: trigger
name: WhoB End
hierarchy:
- Levi_Ataxia
- MINE ALL MINE
- locate_relay
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
- pattern: ^Total: \d+
  type: 1
]]--

if LocateSystem.whobActive then
  LocateSystem.whobFinish()
elseif LocateWorld.whobActive then
  LocateWorld.whobFinish()
end
