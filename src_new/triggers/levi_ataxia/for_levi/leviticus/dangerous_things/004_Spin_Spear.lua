--[[mudlet
type: trigger
name: Spin Spear
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Misc Tracking
- Warnings
- Dangerous Things
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
- pattern: ^(\w+) begins to rapidly spin .+ in a defensive pattern.$
  type: 1
]]--

if type(target) == "string" and isTargeted(matches[2]) then
	selectString(line, 1)
	fg("red")
	setBold(true)
	resetFormat()
	send("cq eqbal")
	ataxia_boxEcho("STOP ATTACKING "..matches[2]:upper(), "black:red")
	
end