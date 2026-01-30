--[[mudlet
type: trigger
name: Speed Stripped
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Remove Afflictions
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
- pattern: ^Directing your will upon (\w+), you tear away the protection granted to \w+ by the speed elixir.$
  type: 1
- pattern: ^(\w+) suddenly seems less dexterous, \w+ reactions becoming noticeably slower.$
  type: 1
- pattern: ^You curse your doll to move slowly and tardily, and (\w+)'s speed defence is removed.$
  type: 1
]]--

if isTargeted(matches[2]) then
	selectString(line,1)
	setBold(true)
	fg("LightSkyBlue")
	resetFormat()
	tarAffed("nospeed")
end