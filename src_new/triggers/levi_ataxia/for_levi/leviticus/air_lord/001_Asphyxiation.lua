--[[mudlet
type: trigger
name: Asphyxiation
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes A-J
- Air Lord
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
- pattern: ^You rip the air from the lungs of (\w+) in a single instant, blood and mucus dripping from her mouth as \w+ doubles
    over with hacking coughs.$
  type: 1
]]--

if isTargeted(matches[2]) then
	tarAffed("asphyxiation")
	if ataxiaTemp.asphyxTimer then killTimer( ataxiaTemp.asphyxTimer ) end
	ataxiaTemp.asphyxTimer = tempTimer(30, [[ erAff("asphyxiation"); ataxiaEcho("Target's no longer asphyxiated.") ]])
end