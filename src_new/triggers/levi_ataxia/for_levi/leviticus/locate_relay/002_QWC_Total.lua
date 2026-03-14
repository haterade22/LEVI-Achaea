--[[mudlet
type: trigger
name: QWC Total
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
- pattern: (\d+) total\)\.?
  type: 1
]]--

if LocateWorld and LocateWorld.city == "world" and not LocateWorld.running and #LocateWorld.queue > 0 then
  tempTimer(0.3, function() LocateWorld.beginQueue() end)
elseif not LocateSystem.running and LocateSystem.city ~= "" and #LocateSystem.queue > 0 then
  tempTimer(0.3, function() LocateSystem.beginQueue() end)
end
