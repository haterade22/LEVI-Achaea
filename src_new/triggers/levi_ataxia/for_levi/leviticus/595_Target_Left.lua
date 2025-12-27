--[[mudlet
type: trigger
name: Target Left
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
- pattern: ^The outline of (\w+) fades away to the (\w+).$
  type: 1
- pattern: ^(\w+) leaves to the (\w+).$
  type: 1
- pattern: ^(\w+) slips away to the (\w+).$
  type: 1
- pattern: ^(\w+)'s somersault takes \w+ out of the room to the (\w+).$
  type: 1
- pattern: ^(\w+) tumbles out to the (\w+).$
  type: 1
- pattern: ^(\w+) gathers \w+ legs under \w+ and backflips out to the (\w+).$
  type: 1
- pattern: ^(\w+), riding .+ leaves to the (\w+).$
  type: 1
- pattern: ^(\w+), riding .+ gathers the reins and jumps off to the (\w+).$
  type: 1
- pattern: ^(\w+) leaps majestically to the (\w+).$
  type: 1
- pattern: ^(\w+) bounds powerfully to the (\w+).$
  type: 1
- pattern: ^(\w+) prowls out to the (\w+), moving like a jaguar.$
  type: 1
- pattern: ^The pop and crackle of lightning follows (\w+) as \w+ leaves to the (\w+).$
  type: 1
- pattern: ^(\w+) departs to the (\w+), the air vibrating wildly around \w+.$
  type: 1
- pattern: ^(\w+) slowly hobbles (\w+).$
  type: 1
- pattern: ^(\w+), riding .+ departs to the (\w+), .+.$
  type: 1
- pattern: ^(\w+) departs to the (\w+), leaving a fearsome roar in \w+ wake.$
  type: 1
- pattern: ^(\w+) glances (\w+) and vanishes.$
  type: 1
- pattern: ^(\w+), riding .+ glances (\w+) and vanishes.$
  type: 1
- pattern: ^Mystic waters rise about (\w+), the frothing crest of a surging wave carrying \w+ away to the (\w+).$
  type: 1
- pattern: ^(\w+) departs to the (\w+), the air sizzling around (\w+).$
  type: 1
- pattern: ^Frosty scales scatter around (\w+) as (she|he) leaves to the (\w+).$
  type: 1
- pattern: ^Carried atop the wave, (\w+) vanishes to the (\w+).$
  type: 1
- pattern: ^(\w+) leaves to the (\w+), (.+).$
  type: 1
- pattern: ^(\w+) launches himself to the (\w+) in a great leap.$
  type: 1
- pattern: ^(\w+) launches herself to the (\w+) in a great leap.$
  type: 1
- pattern: ^(\w+)  stomps out to the (\w+) , shaking the ground with each step.$
  type: 1
- pattern: ^(\w+) glances to the (\w+) and vanishes.$
  type: 1
- pattern: ^(\w+) moves his huge bulk to the (\w+) with surprising grace.$
  type: 1
- pattern: ^(\w+) moves her huge bulk to the (\w+) with surprising grace.$
  type: 1
]]--

if type(target) ~= "string" then
	return false
end

if isTargeted(matches[2]) then
	selectString(line,1)
	fg("black") bg("LightSkyBlue")
	resetFormat()
	dir_left = matches[3]
  engaged = false

	if not string.find(matches[1], "tumble") then
		tAffs.paralysis = false
	end

	ataxia_boxEcho(target.." HAS LEFT TO THE "..dir_left, "black:green")
  ataxia_boxEcho(target.." HAS LEFT TO THE "..dir_left, "black:green")

	if not chasing_Targets then cecho("<red>           -= Target chasing is currently disabled =-") return end
  
  if gmcp.Char.Status.class == "Infernal" and gmcp.Char.Vitals.charstats[4] ~= "Spec: Dual Blunt" then
  send("queue addclear free lunge "..target..";tyranny")
elseif jumping and jumping == true then
	sendAll("cq all", "queue addclear free mountjump "..dir_left)
  elseif not jumping or jumping == false then

	sendAll("cq all;queue addclear free "..dir_left)
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
end