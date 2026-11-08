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

-- The line names no one, so it may be anyone ghosted. It was read as our target's departure
-- every time: the queue cleared, the target's paralysis erased, the target marked gone with the
-- TargetOutOfRoom timer started (which erases afflictions she still has), and, with chasing on,
-- a walk out after the ghost. GMCP's room list (ataxia.playersHere, update_stuff/001) decides:
-- the target left only when it no longer lists her.
-- Other players' clients name the ghost just AFTER the line, before the prompt:
-- "[northwest - Seurimas (1)]" in kb/raw/logs/2026-11-01_elmer_alchemist-vs-serpent_loss_Z5cyffxx.txt
-- at 2832-2833, "[west - Kalys (1)]" in kb/raw/logs/2026-11-01_elmer_shikudo-vs-serpent_noresult_g-lD00-h.txt
-- at 463-465. So GMCP's RemovePlayer may come after the line in the same packet, and a target
-- still listed is checked again on a zero-delay timer, once the packet is read. With no list the
-- old reading holds: she is gone.
-- The name compare is 641's (and isTargeted's, 016): case is ignored, and either name may start
-- the other. It does not call updateTarget.
local ghostDir, ghostLine = matches[2], matches[1]

local function targetListedHere()
  if type(target) ~= "string" or target == "" or type(ataxia) ~= "table"
    or type(ataxia.playersHere) ~= "table" then
    return false
  end
  local want = target:lower()
  for _, name in ipairs(ataxia.playersHere) do
    if type(name) == "string" and name ~= "" then
      local have = name:lower()
      if have:sub(1, #want) == want or want:sub(1, #have) == have then return true end
    end
  end
  return false
end

local function targetLeft()
	dir_left = ghostDir

	if not string.find(ghostLine, "tumble") then
		erAff("paralysis")
	end

	ataxia_boxEcho(target.." HAS LEFT TO THE "..dir_left, "black:green")

	-- CLEANUP BEFORE THE CHASE DECISION (v4.7.275) -- see 637_Target_Left.lua for the full
	-- reasoning. Chasing disabled means "do not follow", never "do not clean up": leaving
	-- the queue loaded fires our combo into an empty room.
	send("cq all")
	targetIshere = false
	enableTimer("TargetOutOfRoom")

	if not chasing_Targets then cecho("<red>           -= Target chasing is currently disabled =-") return end
	-- "to the ether" (kb/raw/logs/2026-11-01_elmer_alchemist-vs-serpent_loss_Z5cyffxx.txt:3425) is
	-- not an exit, so "queue addclear free ether" queued a move the game cannot make. combatQueue
	-- (003) already skips "ether" in its chase piece.
	if dir_left == "ether" then
		cecho("<red>           -= Target left to the ether: no exit to follow =-")
	elseif jumping and jumping == true then
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

	-- (targetIshere / TargetOutOfRoom run above the chase decision; the copy that sat here ran
	-- them twice.)

	if ataxiaTemp.repeatOffence and not ataxiaTemp.doRepeat and chasing_Targets then
		enableTrigger("Repeat Offence")
	end
end

if not targetListedHere() then
	targetLeft()
else
	tempTimer(0, function()
		if type(target) == "string" and not targetListedHere() then targetLeft() end
	end)
end
