--[[mudlet
type: trigger
name: Cursewarded
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
- pattern: ^You try to curse (\w+), but \w+ is warded.$
  type: 1
- pattern: ^A shimmering curseward appears around (\w+).$
  type: 1
- pattern: ^You stare at (\w+), giving \w+ the evil eye, but \w+ is warded.$
  type: 1
]]--

if isTargeted(matches[2]) then
	selectString(line, 1)
	fg("black")
	bg("yellow")
	resetFormat()
	targetIshere = true
	tAffs.curseward = true
end