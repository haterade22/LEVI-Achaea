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

-- Per-class manual attack cooldown overrides (seconds).
-- Falls back to ataxiaBasher.attackCooldown or 0.4s if not listed.
ataxiaBasher_attackCooldowns = {
  -- Example overrides (used before enough GMCP samples are collected):
  -- Serpent = 1.3,
  -- Shaman = 0.8,
  -- ["Blue Dragon"] = 0.5,
}

-- GMCP-based balance tracking: learns actual balance/equilibrium recovery times per class.
-- Measures the interval between consecutive attacks as the effective cooldown.
-- Stores up to 20 samples per class and uses the rolling average.
ataxiaBasher_balanceSamples = ataxiaBasher_balanceSamples or {}
ataxiaBasher_lastAttackEpoch = nil

-- Called each time an attack fires. Measures inter-attack interval to learn balance time.
function ataxiaBasher_recordBalanceSample()
  local now = getEpoch()
  if not ataxiaBasher_lastAttackEpoch then
    ataxiaBasher_lastAttackEpoch = now
    return
  end

  local elapsed = now - ataxiaBasher_lastAttackEpoch
  ataxiaBasher_lastAttackEpoch = now

  -- Only record sane values (0.2s to 5s)
  if elapsed < 0.2 or elapsed > 5.0 then return end

  local class = gmcp.Char.Status.class:title():gsub(" Lady", ""):gsub(" Lord", "")
  if not ataxiaBasher_balanceSamples[class] then
    ataxiaBasher_balanceSamples[class] = {}
  end

  table.insert(ataxiaBasher_balanceSamples[class], elapsed)
  -- Keep last 20 samples
  if #ataxiaBasher_balanceSamples[class] > 20 then
    table.remove(ataxiaBasher_balanceSamples[class], 1)
  end
end

-- Returns the attack cooldown for the current class.
-- Prefers learned GMCP balance times (needs >= 3 samples), then manual overrides, then default.
function ataxiaBasher_getAttackCooldown()
  local class = gmcp.Char.Status.class:title():gsub(" Lady", ""):gsub(" Lord", "")

  -- Use learned balance times if we have enough samples
  local samples = ataxiaBasher_balanceSamples[class]
  if samples and #samples >= 3 then
    local sum = 0
    for _, t in ipairs(samples) do sum = sum + t end
    local avg = sum / #samples
    -- Use 95% of observed average as the cooldown (timer fires just before balance returns,
    -- then canBals() gates the actual attack on the next prompt)
    return avg * 0.95
  end

  -- Fallback to manual overrides or default
  return ataxiaBasher_attackCooldowns[class] or ataxiaBasher.attackCooldown or 0.4
end

function ataxiaBasher_patterns()

  if ataxiaTemp.bashFlee then return end
  if ataxiaBasher.paused then return end
	--if not ataxiaBasher.paused and (speedWalkCounter < 1 or mmp.paused == true) and not autoHarvesting and not autoExtracting then
	if not ataxiaBasher.paused and (mmp.speedWalkCounter < 1 or mmp.paused == true) and not autoHarvesting and not autoExtracting then

    if not ataxiaBasher_skipRoom then
			if canBals() and canStand() then
				if found_target and not ataxiaBasher_atk then
          if gmcp.Char.Status.class == "Magi" then
            ataxiaBasher_magiBashing()
            ataxiaBasher_attack()
					  ataxiaBasher_atk = true
					  ataxiaBasher_recordBalanceSample()
					  tempTimer(ataxiaBasher_getAttackCooldown(), [[ataxiaBasher_atk=false]])
          else
					ataxiaBasher_attack()
					ataxiaBasher_atk = true
					ataxiaBasher_recordBalanceSample()
					tempTimer(ataxiaBasher_getAttackCooldown(), [[ataxiaBasher_atk=false]])
          end
				elseif not found_target and not ataxiaBasher.manual then
					if mmp.paused then
						ataxiaBasher_roomBashed()
						mmp.pause("off")
						send(" ")
          else
            ataxiaBasher_nextRoom()
          end
				end
			end
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
	--elseif not ataxiaBasher.manual and (speedWalkCounter < 1 or mmp.paused == true) then
  elseif not ataxiaBasher.manual and (mmp.speedWalkCounter < 1 or mmp.paused == true) then
	
		if mmp.paused then
			ataxiaBasher_roomBashed()
			mmp.pause("off")
			send(" ")
    else
      ataxiaBasher_nextRoom()
    end
	end
ataxiaBasher_stormhammer()		
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
   ataxiaBasher_stormhammer()
end

function ataxiaBasher_manual()
	mmp.pause("off")
	if not ataxiaBasher.enabled then
		ataxiaEcho("Bashing module engaged. Manual movement required.")
		ataxiaBasher.enabled = true
		ataxiaBasher.paused = false
		ataxiaBasher.manual = true
		ataxiaBasher.areabash = false
		ataxiaBasher_lastAttackEpoch = nil
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
	if ataxiaBasher.targetList[curArea] then
		ataxiaEcho("Complete control sacrificed. Walking to start of slaughter path.")
		ataxiaBasher.enabled = true
		ataxiaBasher.paused = false
		ataxiaBasher.manual = false
		ataxiaBasher.areabash = true
		ataxiaBasher_lastAttackEpoch = nil
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