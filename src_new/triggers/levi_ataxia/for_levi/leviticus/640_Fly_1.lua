--[[mudlet
type: trigger
name: Fly
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
- pattern: ^(\w+) is quickly carried up into the skies.$
  type: 1
- pattern: ^(\w+) crouches down upon \w+ haunces, then with a powerful thrust
  type: 1
- pattern: ^(\w+) vanishes from sight as \w+ is carried into the sky at incredible speed.$
  type: 1
- pattern: ^(\w+) sucks in \w+ breath, and with a mighty blast of air exhales while uttering a word of magic. Suddenly, \w+
    is lifted into the skies by an unseen force.$
  type: 1
- pattern: ^(\w+) grabs hold of a nearby branch and swings up and out of sight into the treetops.$
  type: 1
- pattern: ^(\w+) begins to flap (\w+) wings powerfully, and rises quickly up into the firmament.$
  type: 1
- pattern: ^(\w+) spreads (\w+) arms wide, a tide of darkness boiling up from the ground and sending (\w+) aloft.$
  type: 1
]]--

if type(target) ~= "string" then
	return false
end

if isTargeted(matches[2]) then
	selectString(line,1)
	fg("black") bg("blue")
	resetFormat()
	dir_left = "fly"
	tAffs.paralysis = false
	tAffs.vertigo = false
	if removeAffV3 then removeAffV3("paralysis"); removeAffV3("vertigo") end
  send("pt " ..target.. ": Flying!")
  if gmcp.Char.Status.class == "Runewarden" and rtiwaz == true then
    send("queue addclear free empower tiwaz " ..target)
  else
    send("queue addclear free touch tentacle " ..target)
  end
end
  if tChaseTimer then
		killTimer(tostring(tChaseTimer))
 	end
 	tChaseTimer = tempTimer(2.3, [[tChaseTimer = nil]])

	targetIshere = false
	enableTimer("TargetOutOfRoom")
	
