--[[mudlet
type: trigger
name: LEFT FOLLOW
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
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
- pattern: ^(\w+) leaves, following (\w+) to the (\w+).$
  type: 1
]]--

if type(target) ~= "string" then
	return false
end

depdistort = false

if isTargeted(matches[3]) then
	selectString(line,1)
	fg("black") bg("LightSkyBlue")
	resetFormat()
	dir_left = matches[4]

	if not string.find(matches[1], "tumble") then
		tAffs.paralysis = false
		if removeAffV3 then removeAffV3("paralysis") end
	end

	ataxia_boxEcho(target.." HAS LEFT TO THE "..dir_left, "black:green")

	if not chasing_Targets then cecho("<red>           -= Target chasing is currently disabled =-") return end

	sendAll("cq all;queue addclear free "..dir_left)

	if tChaseTimer then
		killTimer(tostring(tChaseTimer))
 	end
 	tChaseTimer = tempTimer(2.5, [[tChaseTimer = nil]])

	if ataxiaTemp.tarTumble then ataxiaTemp.tarTumble = nil end
	if ataxiaTemp.tumbleTimer then killTimer(ataxiaTemp.tumbleTimer) end

	targetIshere = false
	enableTimer("TargetOutOfRoom")
	
	if ataxiaTemp.repeatOffence and not ataxiaTemp.doRepeat and chasing_Targets then
		enableTrigger("Repeat Offence")
	end
end