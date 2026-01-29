--[[mudlet
type: script
name: search_targets
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
eventHandlers:
- targets updated
]]--

-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Ataxia-DownloadThis > Basher > Bashing > genRunning > search_targets

-- Track which room we've already drawn ldeck cards for
ataxiaBasher.ldeckDrawnRoom = nil

-- Data-driven ldeck rules: { mob = "mob name", count = N, cards = {"maran", "matic", ...} }
-- Add entries for any area/mob combination where pre-combat draws are needed.
if not ataxiaBasher.ldeckRules then
  ataxiaBasher.ldeckRules = {
    { mob = "an elite mhun keeper", count = 3, cards = {"maran", "matic"} },
    { mob = "a mhun knight",        count = 3, cards = {"maran"} },
    { mob = "a mhun knight",        count = 4, cards = {"maran", "matic"} },
  }
end

-- Helper to count specific mob types in current room
function ataxiaBasher_countMobsInRoom(mobName)
  local count = 0
  for id, mob in pairs(ataxia.denizensHere) do
    if mob:lower() == mobName:lower() then
      count = count + 1
    end
  end
  return count
end

-- Draw ldeck cards before combat for dangerous multi-target rooms
function ataxiaBasher_preCombatLdeck()
  local roomId = gmcp.Room.Info.num

  -- Skip if we already drew for this room
  if ataxiaBasher.ldeckDrawnRoom == roomId then
    return false
  end

  -- Evaluate all rules and collect which cards to draw
  local cardsToDraw = {}
  for _, rule in ipairs(ataxiaBasher.ldeckRules) do
    local mobCount = ataxiaBasher_countMobsInRoom(rule.mob)
    if mobCount >= rule.count then
      for _, card in ipairs(rule.cards) do
        cardsToDraw[card] = true
      end
    end
  end

  -- Send ldeck draws using queue system
  local drew = false
  for card, _ in pairs(cardsToDraw) do
    send("queue add free ldeck draw " .. card)
    drew = true
  end

  if drew then
    ataxiaBasher.ldeckDrawnRoom = roomId
    return true
  end

  return false
end

function search_targets()
	if (not ataxiaBasher.enabled) or need_roomCheck then return false end
  if autoHarvesting or autoExtracting then return false end
	found_target = false
	if ataxiaBasher_skipRoom then return false end
	if not ataxiaBasher.targetList[gmcp.Room.Info.area] then return false end
	
  for i,v in pairs(ataxia.denizensHere) do
		if tonumber(i) == target then
			found_target = true
			return
 
		end
  end
	
	if not found_target then
		for num,npc in pairs(ataxiaBasher.targetList[gmcp.Room.Info.area]) do
			if num ~= "keyword" then
				for id,mob in pairs(ataxia.denizensHere) do
					if mob:lower() == npc:lower() then
						target=tonumber(id)
						secondTarget = mob
						found_target = true
						send("st "..target)
						if ataxiaBasher.manual then
							ataxiaEcho("Now targeting: "..target)
              send("pt Target: " ..target)
						end
						raiseEvent("changed target")
						--if speedWalkCounter > 0 and not mmp.paused then mmp.pause("on") end
						if mmp.speedWalkCounter > 0 and not mmp.paused then mmp.pause("on") end
            ataxiaBasher_preCombatLdeck()
            return
					end
				end
			end
		end
	end
  ataxiaBasher_stormhammer()
end

-- Configurable shield retarget timers per mob (seconds).
-- When a mob shields, the basher swaps to another target for this duration, then swaps back.
-- Default is ataxiaBasher.shieldTimerDefault (3.1s) if the mob isn't listed.
if not ataxiaBasher.shieldTimers then
  ataxiaBasher.shieldTimers = {
    ["a mhun knight"] = 4.7,
  }
end
ataxiaBasher.shieldTimerDefault = ataxiaBasher.shieldTimerDefault or 3.1

-- Cache flag: set to true when room contents change, cleared after recompute
ataxiaBasher_stormhammerDirty = true

function ataxiaBasher_stormhammer(forceRefresh)
  if not forceRefresh and not ataxiaBasher_stormhammerDirty then return end
  stormhammerTargets = {}
  if not ataxiaBasher.targetList[gmcp.Room.Info.area] then return end
  for k,v in pairs(ataxia.denizensHere) do
    if (table.contains(ataxiaBasher.targetList[gmcp.Room.Info.area], v)) then
      table.insert(stormhammerTargets, tostring(k))
    end
  end
  ataxiaBasher_stormhammerDirty = false
end

-- Call this on room change or denizen list update to invalidate the cache
function ataxiaBasher_invalidateStormhammer()
  ataxiaBasher_stormhammerDirty = true
end

function ataxiaBasher_retargetShielded()

  target = ataxiaTemp.retarget
  secondTarget = ataxiaTemp.retargetsecond
  basher_needAction = true
  ataxiaTemp.retarget = nil
  ataxiaTemp.retargetsecond = nil
  raiseEvent("changed target")
  bashConsoleEcho("denizen", "Retargeting previous target")
  if ataxiaTemp.mobshieldtimer then killTimer(ataxiaTemp.mobshieldtimer); ataxiaTemp.mobshieldtimer = nil end
  if ataxiaBasher.manual then
    ataxiaEcho("Unshielded, changing back to: "..target)
  end  
  send("st "..target,false)
  ataxiaBasher_stormhammer()
end

function ataxiaBasher_shieldedTarget()

  found_target = false
  for num, npc in pairs(ataxiaBasher.targetList[gmcp.Room.Info.area]) do
    if num ~= "keyword" and not found_target then
      for id, mob in pairs(ataxia.denizensHere) do
        if mob:lower() == npc:lower() then
          if target ~= tonumber(id) then
            ataxiaTemp.retarget = target
            ataxiaTemp.retargetsecond = secondTarget
            target = tonumber(id)
            secondTarget = mob
            found_target = true
            basher_needAction = true
            send("st "..target,false)
						if ataxiaBasher.manual then
							ataxiaEcho("Shielded, changing to: "..target)
						end
						raiseEvent("changed target")
            if ataxiaTemp.mobshieldtimer then killTimer(ataxiaTemp.mobshieldtimer); ataxiaTemp.mobshieldtimer = nil end
            local shieldDuration = (ataxiaBasher.shieldTimers and ataxiaBasher.shieldTimers[ataxiaTemp.retargetsecond])
              or ataxiaBasher.shieldTimerDefault or 3.1
            ataxiaTemp.mobshieldtimer = tempTimer(shieldDuration, [[ ataxiaBasher_retargetShielded() ]])
            return
          end
        end
      end
    end
  end   
  ataxiaBasher_stormhammer()         
end

function ataxiaBasher_validTargets()
  ataxiaBasher_stormhammer()
  return #stormhammerTargets
end