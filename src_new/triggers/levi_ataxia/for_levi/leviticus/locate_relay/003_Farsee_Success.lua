--[[mudlet
type: trigger
name: Farsee Success
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
- pattern: ^You see that (\w+) is located at (.+)\.$
  type: 1
]]--

local name = matches[2]
local room = matches[3]
if LocateSystem.running and LocateSystem.current and LocateSystem.current:lower() == name:lower() then
  LocateSystem.handleResult(name, room)
elseif LocateWorld.running and LocateWorld.current and LocateWorld.current:lower() == name:lower() then
  LocateWorld.handleResult(name, room)
end
