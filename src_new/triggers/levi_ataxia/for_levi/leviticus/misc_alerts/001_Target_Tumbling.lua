--[[mudlet
type: trigger
name: Target Tumbling
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Misc Tracking
- Warnings
- Misc Alerts
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
- pattern: ^(\w+) begins to tumble towards the \w+.$
  type: 1
]]--

if isTargeted(matches[2]) then
	selectString(line, 1)
	fg("orange")
	setBold(true)
	resetFormat()
	ataxia_boxEcho("TARGET IS TUMBLING - CANCEL IT!", "black:orange")
	ataxiaTemp.tarTumble = true
	if ataxiaTemp.tumbleTimer then killTimer(ataxiaTemp.tumbleTimer) end
	ataxiaTemp.tumbleTimer = tempTimer(5, [[ataxiaTemp.tarTumble = nil;
		ataxiaTemp.tumbleTimer = nil;
	]])
end