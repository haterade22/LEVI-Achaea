--[[mudlet
type: trigger
name: MIND THROWN
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
- pattern: ^You are jolted violently (\w+)wards by powers unseen.$
  type: 1
]]--




	selectString(line,1)
	fg("black") bg("LightSkyBlue")
	resetFormat()
  
  if matches[2] == "southeast" then 
	dir_left = "northwest"
  elseif matches[2] == "southwest" then 
	dir_left = "northeast"
   elseif matches[2] == "northwest" then 
	dir_left = "southeast"
     elseif matches[2] == "northeast" then 
	dir_left = "southwest"
     elseif matches[2] == "north" then 
	dir_left = "south"
       elseif matches[2] == "south" then 
	dir_left = "north"
       elseif matches[2] == "up" then 
	dir_left = "down"
       elseif matches[2] == "down" then 
	dir_left = "up"
       elseif matches[2] == "east" then 
	dir_left = "west"
       elseif matches[2] == "west" then 
	dir_left = "east"
  
  
  end
  
  




	if not string.find(matches[1], "tumble") then
		tAffs.paralysis = false
	end

	ataxia_boxEcho(target.." GOING BACK TO "..dir_left, "black:green")

	if not chasing_Targets then cecho("<red>           -= Target chasing is currently disabled =-") return end
if jumping then
	sendAll("cq all", "queue addclear free mountjump "..dir_left)
  else

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
