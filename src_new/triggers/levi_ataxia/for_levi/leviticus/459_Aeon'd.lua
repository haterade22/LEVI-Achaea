--[[mudlet
type: trigger
name: Aeon'd
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes A-J
- Depthwalker
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
- pattern: ^Invoking the might of Aeon, you bring down a curse of terrible proportions upon (\w+).$
  type: 1
]]--

if isTargeted(matches[2]) then
	selectString(line,1)
	setBold(true)
	fg("LightSkyBlue")
	resetFormat()
	ataxia_boxEcho(target:upper().." HAS BEEN AEONED!", "black:LightSkyBlue")

end