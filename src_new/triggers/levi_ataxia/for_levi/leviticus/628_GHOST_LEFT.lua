--[[mudlet
type: trigger
name: GHOST LEFT
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
- pattern: ^A ghostly apparition vanishes from sight to the (\w+).$
  type: 1
]]--

if type(target) ~= "string" then
	return false
end


	selectString(line,1)
	fg("black") bg("LightSkyBlue")
	resetFormat()
	dir_left = matches[2]

	if not string.find(matches[1], "tumble") then
		tAffs.paralysis = false
	end

	ataxia_boxEcho(target.." HAS LEFT TO THE "..dir_left, "black:green")

	if not chasing_Targets then cecho("<red>           -= Target chasing is currently disabled =-") return end
if jumping and jumping == true then
	sendAll("cq all", "queue addclear free mountjump "..dir_left)
  elseif not jumping or jumping == false then

	sendAll("cq all", "queue addclear free "..dir_left)
end
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
