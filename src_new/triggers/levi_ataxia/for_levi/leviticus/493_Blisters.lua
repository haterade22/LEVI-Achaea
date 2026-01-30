--[[mudlet
type: trigger
name: Blisters
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes A-J
- Fire Lord
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
- pattern: ^Bending the might of Kkractle upon the pitiful (\w+), you command that \w+ burn from within.$
  type: 1
]]--

if isTargeted(matches[2]) then
  tarAffed("blistered", "burns")
  
  if ataxiaTemp.blisterTimer then killTimer(ataxiaTemp.blisterTimer) end
  ataxiaTemp.blisterTimer = tempTimer(15, [[ erAff("blistered"); ataxiaEcho("Target no longer has blisters.") ]])
end