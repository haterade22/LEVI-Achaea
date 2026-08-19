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
		erAff("paralysis")
	end

	ataxia_boxEcho(target.." HAS LEFT TO THE "..dir_left, "black:green")
  ataxia_boxEcho(target.." HAS LEFT TO THE "..dir_left, "black:green")

	-- CLEANUP BEFORE THE CHASE DECISION (v4.7.275). This block used to sit BELOW the
	-- `chasing_Targets` early return, so with chasing off none of it ran. In the 2026-08-19
	-- Grulk log that meant our queued combo stayed in the server queue and fired into an empty
	-- room -- three refusals ("I do not see anyone by that name here", "You detect nothing here
	-- by that name", "I do not recognise anything called that here") -- and while we stood there
	-- a jade spider hit us four times for 3,509 damage, 4% of our total.
	--
	-- Chasing disabled means "do not follow". It never meant "do not clean up".
	send("cq all")
	targetIshere = false
	enableTimer("TargetOutOfRoom")
	if ataxiaTemp.tarTumble then ataxiaTemp.tarTumble = nil end
	if ataxiaTemp.tumbleTimer then killTimer(ataxiaTemp.tumbleTimer) end

	if not chasing_Targets then cecho("<red>           -= Target chasing is currently disabled =-") return end

  if gmcp.Char.Status.class == "Infernal" and ataxia.vitals.knight ~= "Dual Blunt" then
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

	-- (tarTumble / tumbleTimer / targetIshere / TargetOutOfRoom now run above the chase
	-- decision -- v4.7.275. Duplicates removed rather than left to run twice.)

	if ataxiaTemp.repeatOffence and not ataxiaTemp.doRepeat and chasing_Targets then
		enableTrigger("Repeat Offence")
	end
end