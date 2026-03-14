--[[mudlet
type: trigger
name: QWC Parse
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
- pattern: ^([A-Z][a-z]+(?:,\s[A-Z][a-z]+)*(?:,?\s+and\s+[A-Z][a-z]+)?)\.$
  type: 1
]]--

if LocateWorld and LocateWorld.city == "world" and not LocateWorld.running then
  LocateWorld.parseQW(line)
elseif LocateSystem.running == false and LocateSystem.city ~= "" then
  LocateSystem.parseQWC(line)
end
