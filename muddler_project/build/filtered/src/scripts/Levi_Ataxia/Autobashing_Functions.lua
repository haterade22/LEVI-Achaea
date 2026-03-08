--[[mudlet
type: script
name: Autobashing Functions
hierarchy:
- Levi_Ataxia
- LEVI
- Ataxia
- Basher
- Bashing
- genRunning
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

-- Anti-spam delay (seconds): prevents double-sends during the network round-trip
-- before GMCP reports balance lost. canBals() handles actual balance gating.
local ANTI_SPAM_DELAY = 0.3

-- ============================================================================
-- Swiftcurse charge detection (GMCP-based, works during blackout)
-- Swiftcurse uses EQ only. If we see 2 consecutive EQ recoveries (EQ 0→1)
-- while BAL was never consumed, the swiftcurse charge-up succeeded.
-- ============================================================================
ataxiaBasher_prevEq = nil       -- previous EQ state (true/false)
ataxiaBasher_prevBal = nil      -- previous BAL state (true/false)
ataxiaBasher_eqOnlyCount = 0    -- consecutive EQ-only recoveries

function ataxiaBasher_detectSwiftcurseCharge()
  if not ataxiaBasher.enabled then return end
  if not ataxia_isClass("Shaman") then return end

  local curEq = (gmcp.Char.Vitals.eq == "1")
  local curBal = (gmcp.Char.Vitals.bal == "1")

  -- Detect BAL consumed (went from true to false) → reset counter (normal attack)
  if ataxiaBasher_prevBal == true and not curBal then
    ataxiaBasher_eqOnlyCount = 0
  end

  -- Detect EQ recovery (went from false to true) while BAL stayed up
  if ataxiaBasher_prevEq == false and curEq and ataxiaBasher_prevBal == true and curBal then
    ataxiaBasher_eqOnlyCount = ataxiaBasher_eqOnlyCount + 1
    if ataxiaBasher_eqOnlyCount >= 2 and (curseCharge or 0) <= 1 then
      curseCharge = 15
      ataxiaBasher_eqOnlyCount = 0
    end
  end

  ataxiaBasher_prevEq = curEq
  ataxiaBasher_prevBal = curBal
end

if ataxiaBasher_swiftcurseHandler then
  killAnonymousEventHandler(ataxiaBasher_swiftcurseHandler)
end
ataxiaBasher_swiftcurseHandler = registerAnonymousEventHandler("gmcp.Char.Vitals", "ataxiaBasher_detectSwiftcurseCharge")

-- ============================================================================
-- Global safety throttle: detect runaway attack loops
-- ============================================================================
ataxiaBasher_cmdCount = 0
ataxiaBasher_cmdWindowStart = 0

function ataxiaBasher_throttleCheck()
  local now = getEpoch()
  if now - ataxiaBasher_cmdWindowStart > 1.0 then
    ataxiaBasher_cmdWindowStart = now
    ataxiaBasher_cmdCount = 0
  end
  ataxiaBasher_cmdCount = ataxiaBasher_cmdCount + 1
  if ataxiaBasher_cmdCount > 5 then
    ataxiaEcho("THROTTLE: Excessive attack rate detected (" .. ataxiaBasher_cmdCount .. " in 1s)! Pausing for safety.")
    ataxiaBasher_atk = true
    if ataxiaBasher_atkTimer then killTimer(ataxiaBasher_atkTimer) end
    ataxiaBasher_atkTimer = tempTimer(2.0, function()
      ataxiaBasher_atk = false
      ataxiaBasher_atkTimer = nil
    end)
    return false
  end
  return true
end

-- ============================================================================
-- UNIFIED DISPATCH GATE: All attack requests route through here.
-- This is the ONLY function that calls ataxiaBasher_attack().
-- The ataxiaBasher_atk flag is ONLY reset by the timer callback.
-- ============================================================================
function ataxiaBasher_tryAttack()
  -- Hard gate: cooldown active
  if ataxiaBasher_atk then return false end

  -- Hard gate: fleeing or paused
  if ataxiaTemp.bashFlee then return false end
  if ataxiaBasher.paused then return false end

  -- Hard gate: balance/standing
  if not canBals() or not canStand() then return false end

  -- Hard gate: skip room
  if ataxiaBasher_skipRoom then return false end

  -- Hard gate: no target — advance to next room if in auto mode
  if not found_target then
    if not ataxiaBasher.manual then
      if mmp.paused then
        ataxiaBasher_roomBashed()
        mmp.pause("off")
        send(" ")
      else
        ataxiaBasher_nextRoom()
      end
    end
    return false
  end

  -- Safety throttle
  if not ataxiaBasher_throttleCheck() then return false end

  -- All gates passed: fire the attack
  -- Magi needs pre-attack stormhammer/GUI setup
  if gmcp.Char.Status.class == "Magi" then
    ataxiaBasher_magiBashing()
  end

  ataxiaBasher_attack()

  -- Anti-spam cooldown: short timer prevents double-sends during network round-trip.
  -- canBals() (line 134) is the real balance gate via GMCP.
  ataxiaBasher_atk = true
  if ataxiaBasher_atkTimer then killTimer(ataxiaBasher_atkTimer) end
  ataxiaBasher_atkTimer = tempTimer(ANTI_SPAM_DELAY, function()
    ataxiaBasher_atk = false
    ataxiaBasher_atkTimer = nil
  end)

  return true
end

-- ============================================================================
-- Main patterns loop (thin wrapper around tryAttack)
-- ============================================================================
function ataxiaBasher_patterns()
  if not ataxiaBasher.enabled then return end
  if ataxiaTemp.bashFlee then return end
  if ataxiaBasher.paused then return end

  if not ataxiaBasher.paused and (mmp.speedWalkCounter < 1 or mmp.paused == true) and not autoHarvesting and not autoExtracting then
    if not ataxiaBasher_skipRoom then
      ataxiaBasher_tryAttack()
    elseif not ataxiaBasher.manual then
      if mmp.paused then
        ataxiaBasher_roomBashed()
        mmp.pause("off")
        send(" ")
      else
        ataxiaBasher_nextRoom()
      end
    end
  elseif autoHarvesting then
    ataxiaHarvester_check()
  elseif autoExtracting then
    ataxiaExtractor_check()
  elseif not ataxiaBasher.manual and (mmp.speedWalkCounter < 1 or mmp.paused == true) then
    if mmp.paused then
      ataxiaBasher_roomBashed()
      mmp.pause("off")
      send(" ")
    else
      ataxiaBasher_nextRoom()
    end
  end

  -- Single stormhammer refresh per prompt cycle (dirty-flag gated)
  if ataxiaBasher_stormhammerDirty then
    ataxiaBasher_stormhammer()
  end
end

function ataxiaBasher_nextRoom()
  local nextRoom, dist = 0, 9999
  
  if not autoExtracting and not autoHarvesting then
    ataxiaBasher_roomBashed()     
  else
    ataxiaHarvester_harvested()
  end
  if ataxiaBasher.manual then return end
  if #ataxiaBasher_path > 0 then
    if not ataxiaTemp.mapperPath then
      expandAlias("goto "..ataxiaBasher_path[1], false)
    else
      for _, v in ipairs(ataxiaBasher_path) do
        getPath(gCurrentRoom, v)
        if table.size(speedWalkDir) == 1 then
          nextRoom = v
          break
        elseif table.size(speedWalkDir) < dist then
          dist = table.size(speedWalkDir)
          nextRoom = v
        end
      end
      expandAlias("goto "..nextRoom,false)
    end
    ataxiaBasher_startStuckTimer()
  else
    ataxiaBasher_areaoff()
  end
end

function ataxiaBasher_manual()
	mmp.pause("off")
	if not ataxiaBasher.enabled then
		ataxiaEcho("Bashing module engaged. Manual movement required.")
		ataxiaBasher.enabled = true
		ataxiaBasher.paused = false
		ataxiaBasher.manual = true
		ataxiaBasher.areabash = false
		raiseEvent("basher enabled")
	else
		ataxiaBasher.enabled = false
		ataxiaBasher.paused = false
		ataxiaBasher.manual = false
		ataxiaBasher.areabash = false
		ataxiaEcho("Bashing systems disengaged.")
		raiseEvent("basher disabled")
	end
end

function ataxiaBasher_areabash()
	mmp.pause("off")
	local curArea = gmcp.Room.Info.area
	if not ataxiaBasher.targetList then
		ataxiaEcho("Bashing systems not yet loaded. Run 'ataxia setup' or 'abinstall' first.")
		return
	end
	if ataxiaBasher.targetList[curArea] then
		ataxiaEcho("Complete control sacrificed. Walking to start of slaughter path.")
		ataxiaBasher.enabled = true
		ataxiaBasher.paused = false
		ataxiaBasher.manual = false
		ataxiaBasher.areabash = true
		ataxiaBasher_generatePath()
		raiseEvent("basher enabled")
	end
end

function ataxiaBasher_areaoff()
	mmp.pause("off")
	ataxiaBasher.enabled = false
	ataxiaBasher.paused = false
	ataxiaBasher.manual = false
	ataxiaBasher.areabash = false
	ataxiaEcho("Bashing systems disengaged.")
	raiseEvent("basher disabled")
end