--[[mudlet
type: script
name: Bashing Functions
hierarchy:
- Levi_Ataxia
- LEVI
- Ataxia
- Basher
- Bashing
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

--[[mudlet
type: script
name: Bashing Functions
hierarchy:
- Levi_Ataxia
- LEVI
- Ataxia
- Basher
- Bashing
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Ataxia-DownloadThis > Basher > Bashing > Bashing Functions

-- Dispatch table: initialized once at script load time instead of every attack
ataxiaBasher_bashingFuncs = {
  --Elementals
  ["Air Elemental"] = "ataxiaBasher_aEleBashing",
  ["Fire Elemental"] = "ataxiaBasher_fEleBashing",
  ["Water Elemental"] = "ataxiaBasher_wEleBashing",
  ["Earth Elemental"] = "ataxiaBasher_eEleBashing",
  --Dragons
  ["Blue Dragon"] = "ataxiaBasher_dragonBashing",
  ["Black Dragon"] = "ataxiaBasher_dragonBashing",
  ["Green Dragon"] = "ataxiaBasher_dragonBashing",
  ["Golden Dragon"] = "ataxiaBasher_dragonBashing",
  ["Red Dragon"] = "ataxiaBasher_dragonBashing",
  ["Silver Dragon"] = "ataxiaBasher_dragonBashing",
  --Standard Classes
  Alchemist = "ataxiaBasher_alchemistBashing",
  Apostate = "ataxiaBasher_apostateBashing",
  Bard = "ataxiaBasher_bardBashing",
  Blademaster = "ataxiaBasher_blademasterBashing",
  Depthswalker = "ataxiaBasher_depthswalkerBashing",
  Infernal = "ataxiaBasher_infernalBashing",
  Jester = "ataxiaBasher_jesterBashing",
  Magi = "ataxiaBasher_magiBashing",
  Monk = "ataxiaBasher_monkBashing2",
  Occultist = "ataxiaBasher_occultistBashing",
  Paladin = "ataxiaBasher_paladinBashing",
  Pariah = "ataxiaBasher_pariahBashing",
  Priest = "ataxiaBasher_priestBashing",
  Psion = "ataxiaBasher_psionBashing",
  Runewarden = "ataxiaBasher_runewardenBashing",
  Sentinel = "ataxiaBasher_sentinelBashing",
  Serpent = "ataxiaBasher_serpentBashing",
  Shaman = "ataxiaBasher_shamanBashing",
  Sylvan = "ataxiaBasher_sylvanBashing",
  Unnamable = "ataxiaBasher_knightBashing",
}

function ataxiaBasher_attack()
  -- Determine danger level (flee/shield/attack/wait) — single check, no redundant logic
  local danger = ataxiaBasher_dangerLevel()

  if danger == "flee" then
    ataxiaBasher_executeFlee()
    return
  end

  if danger == "wait" then return end

  -- Player flee check (per-area configurable)
  if ataxiaBasher_checkPlayerFlee() then return end

  -- Diagnose if too many unknown afflictions
  if ataxia.afflictions.unknown and ataxia.afflictions.unknown >= 2 and not sent_diagnose then
    send("queue addclear freestand diagnose", false)
    sent_diagnose = tempTimer(3, [[sent_diagnose = nil]])
    return
  end

  if danger == "shield" then
    send("queue addclear freestand touch shield")
    return
  end

  -- danger == "attack"
  local class = gmcp.Char.Status.class:title():gsub(" Lady", ""):gsub(" Lord", "")

  -- If shielded, wait until HP recovers before dropping shield to attack
  -- Standing/leg checks removed: server-side "freestand stand" handles this in PvE.
  if ataxia.defences.shield then
    if ataxia.vitals.hpp >= 70 and ataxiaBasher_bashingFuncs[class] then
      ataxiaBasher_assembleAttack()
    end
  elseif ataxiaBasher_bashingFuncs[class] then
    ataxiaBasher_assembleAttack()
  elseif not ataxiaBasher_bashingFuncs[class] then
    ataxiaEcho(class.." isn't supported yet, sorry!")
  end
end

-- ============================================================================
-- Damage tracking for extreme damage rate detection
-- ============================================================================
ataxiaBasher_dmgSamples = ataxiaBasher_dmgSamples or {}
ataxiaBasher_dmgWindowSec = 5

function ataxiaBasher_recordDamage(amount)
  if not ataxiaBasher.enabled then return end
  if amount <= 0 then return end
  table.insert(ataxiaBasher_dmgSamples, {getEpoch(), amount})
  local cutoff = getEpoch() - ataxiaBasher_dmgWindowSec
  while #ataxiaBasher_dmgSamples > 0 and ataxiaBasher_dmgSamples[1][1] < cutoff do
    table.remove(ataxiaBasher_dmgSamples, 1)
  end
end

function ataxiaBasher_isDamageRateExtreme()
  if #ataxiaBasher_dmgSamples < 2 then return false end
  local cutoff = getEpoch() - ataxiaBasher_dmgWindowSec
  local totalDmg = 0
  for _, s in ipairs(ataxiaBasher_dmgSamples) do
    if s[1] >= cutoff then totalDmg = totalDmg + s[2] end
  end
  local threshold = (ataxia.vitals.maxhp or 5000) * 0.6
  return totalDmg >= threshold
end

-- ============================================================================
-- Layered defense: percentage-based thresholds (backward-compatible)
-- ============================================================================
function ataxiaBasher_initThresholds()
  if not ataxiaBasher.fleeThresholdPct then
    if ataxiaBasher.fleeThreshold and ataxiaBasher.fleeThreshold > 100
       and ataxia.vitals.maxhp and ataxia.vitals.maxhp > 0 then
      ataxiaBasher.fleeThresholdPct = math.floor((ataxiaBasher.fleeThreshold / ataxia.vitals.maxhp) * 100)
    else
      ataxiaBasher.fleeThresholdPct = 25
    end
  end
  if not ataxiaBasher.shieldThresholdPct then ataxiaBasher.shieldThresholdPct = 40 end
  if not ataxiaBasher.fleeRecoveryPct then ataxiaBasher.fleeRecoveryPct = 70 end
  if not ataxiaBasher.bloodMaidenBosses then
    ataxiaBasher.bloodMaidenBosses = {
      ["Rhuzios, the Mummy Lord"] = true,
      ["Underlord Seroth"] = true,
      ["Underlord Dreyvos"] = true,
    }
  end
  if not ataxiaBasher.safeRooms then
    ataxiaBasher.safeRooms = {
      ["The Alcazar"] = { room = 53454, recoveryPct = 100 },
    }
  end
end

-- Returns: "attack", "shield", "flee", or "wait"
function ataxiaBasher_dangerLevel()
  if ataxiaTemp.bashFlee then return "wait" end

  local hpp = ataxia.vitals.hpp or 0
  if hpp == 0 then return "wait" end

  if ataxia.afflictions.aeon or ataxia.afflictions.paralysis or ataxia.afflictions.peace then
    return "wait"
  end

  ataxiaBasher_initThresholds()

  local inWorldTree = gmcp.Room.Info.area == "the Fathomless Expanse of the World Tree"

  if not inWorldTree then
    local fleePct = ataxiaBasher.fleeThresholdPct or 25
    if hpp <= fleePct then return "flee" end

    if ataxiaBasher_isDamageRateExtreme() then
      ataxiaEcho("DANGER: Extreme incoming damage rate detected! Fleeing.")
      return "flee"
    end
  end

  local shieldPct = ataxiaBasher.shieldThresholdPct or 40
  if hpp <= shieldPct and ataxiaBasher_canShield and ataxiaBasher_canShield() and not ataxia.defences.shield then
    return "shield"
  end

  return "attack"
end

-- Returns the safe room config for the current area, or nil if none configured
function ataxiaBasher_getAreaSafeRoom(area)
  area = area or (gmcp.Room.Info and gmcp.Room.Info.area)
  if not area or not ataxiaBasher.safeRooms then return nil end
  return ataxiaBasher.safeRooms[area]
end

-- ============================================================================
-- Flee execution with movement validation
-- ============================================================================
function ataxiaBasher_executeFlee()
  ataxiaTemp.bashFlee = true
  ataxiaBasher.paused = true
  ataxiaTemp.fleeOriginRoom = tonumber(gmcp.Room.Info.num)
  ataxiaBasher_startFleeTimer()
  send("cq all")
  ataxiagui_updateVitals()

  local cantMove = ataxia.afflictions.paralysis
    or ataxia.afflictions.entangled
    or ataxia.afflictions.webbed
    or ataxia.afflictions.impaled
    or ataxia.afflictions.transfixation
    or ataxia.afflictions.stun

  if cantMove then
    ataxiaEcho("FLEE: Can't move (afflicted). Shielding and waiting for cures.")
    send("touch shield")
    return
  end

  if mmp.paused then mmp.pause("off") end

  local safeConfig = ataxiaBasher_getAreaSafeRoom()
  if safeConfig and safeConfig.room then
    ataxiaEcho("FLEE: HP critical! Retreating to area safe room (v" .. safeConfig.room .. ").")
    expandAlias("goto " .. safeConfig.room)
  elseif mmp.previousroom then
    ataxiaEcho("FLEE: HP critical! Retreating to previous room.")
    expandAlias("goto " .. mmp.previousroom)
  else
    local exits = gmcp.Room.Info and gmcp.Room.Info.exits
    if exits then
      for dir, _ in pairs(exits) do
        ataxiaEcho("FLEE: No previous room. Fleeing " .. dir .. ".")
        send(dir)
        return
      end
    end
    ataxiaEcho("FLEE: No escape route. Shielding.")
    send("touch shield")
  end
end

-- ============================================================================
-- Flee recovery check (called from prompt handler)
-- ============================================================================
function ataxiaBasher_checkFleeRecovery()
  if ataxiaTemp.bashFlee ~= true then return end

  ataxiaBasher_initThresholds()

  -- Wait for 100% HP before returning to the combat room
  local recoveryPct = 100

  if (ataxia.vitals.hpp or 0) >= recoveryPct then
    ataxiaTemp.bashFlee = false
    ataxiaBasher.paused = false
    if ataxiaTemp.fleeCircuitBreaker then
      killTimer(ataxiaTemp.fleeCircuitBreaker)
      ataxiaTemp.fleeCircuitBreaker = nil
    end

    -- Navigate back to the room we fled from
    if ataxiaTemp.fleeOriginRoom
       and ataxiaTemp.fleeOriginRoom ~= tonumber(gmcp.Room.Info.num) then
      ataxiaEcho("HP recovered to 100%. Returning to room v" .. ataxiaTemp.fleeOriginRoom .. ".")
      ataxiaTemp.fleeReturning = true
      if mmp.paused then mmp.pause("off") end
      expandAlias("goto " .. ataxiaTemp.fleeOriginRoom)
      -- Safety timeout for return navigation
      ataxiaTemp.fleeReturnTimer = tempTimer(15, function()
        if ataxiaTemp.fleeReturning then
          ataxiaEcho("Return to flee room timed out. Resuming normal bashing.")
          ataxiaTemp.fleeOriginRoom = nil
          ataxiaTemp.fleeReturning = nil
          ataxiaTemp.fleeReturnTimer = nil
          search_targets()
        end
      end)
    else
      -- Already in the origin room or no origin saved
      ataxiaTemp.fleeOriginRoom = nil
      ataxiaTemp.fleeReturning = nil
      ataxiaEcho("HP recovered to 100%. Resuming bashing.")
      search_targets()
    end
    ataxiagui_updateVitals()
  end
end

-- ============================================================================
-- Player flee check (per-area configurable)
-- ============================================================================
function ataxiaBasher_checkPlayerFlee()
  if not ataxiaBasher.fleeFromPlayers then return false end
  if not ataxiaBasher.fleeFromPlayers[gmcp.Room.Info.area] then return false end
  if type(ataxia.playersHere) ~= "table" then return false end

  for _, player in pairs(ataxia.playersHere) do
    if table.contains(ataxiaBasher.fleeFromPlayers[gmcp.Room.Info.area], player) then
      ataxiaBasher_areaoff()
      ataxiaBasher.paused = true
      expandAlias("mstop")
      send("cq all")
      send("touch shield")
      ataxiaEcho("Hostile player detected: " .. player .. "! Fleeing and disabling basher.")
      return true
    end
  end
  return false
end

function ataxiaBasher_assembleAttack()
  -- Wand of Reflection emergency check (requires toggle + wand ID)
  if ataxiaBasher.wandReflection then
    if not ataxia.wandReflectionThreshold then ataxia.wandReflectionThreshold = 10 end
    if not ataxia.wandReflectionRecovery then ataxia.wandReflectionRecovery = 70 end
    local wandId = ataxiaBasher.wandId or "wand"

    if ataxia.wandReflectionActive then
      -- Currently waiting to recover HP
      if ataxia.vitals.hpp >= ataxia.wandReflectionRecovery then
        ataxia.wandReflectionActive = false
        ataxiaEcho("HP recovered to " .. ataxia.wandReflectionRecovery .. "%, resuming attacks.")
      else
        return  -- Keep waiting, don't attack
      end
    elseif ataxia.vitals.hpp < ataxia.wandReflectionThreshold
       and ataxia.vitals.hpp ~= 0
       and not ataxia.wandReflectionCooldown then
      send("cq all;point " .. wandId .. " at me")
      ataxia.wandReflectionActive = true
      ataxia.wandReflectionCooldown = true
      tempTimer(3600, [[ataxia.wandReflectionCooldown = false]])  -- 1 hour cooldown (wand is hourly)
      ataxiaEcho("EMERGENCY: HP below 10%! Using wand of reflection, pausing until 70% HP.")
      return  -- Skip attack this cycle
    end
  end

  -- Maran emergency barrier check
  if not ataxia.maranThreshold then ataxia.maranThreshold = 25 end
  if ataxia.vitals.hpp < ataxia.maranThreshold
     and ataxia.vitals.hpp ~= 0
     and not ataxia.maranCooldown
     and ataxiaTables.ldeckcardscount
     and ataxiaTables.ldeckcardscount.Maran
     and ataxiaTables.ldeckcardscount.Maran > 0 then
    send("cq all;ldeck draw maran")
    ataxia.maranCooldown = true
    tempTimer(65, [[ataxia.maranCooldown = false]])  -- 65s cooldown (barrier lasts 60s)
    return  -- Skip normal attack this cycle
  end

	get_Battlerage()
	local command = ""
  local class = gmcp.Char.Status.class:title():gsub(" Lady", ""):gsub(" Lord", "")
	local sp = ataxia.settings.separator
	local goldPack = ataxiaBasher.goldPack or "pack436363"
	if ataxiaTemp.goldInRoom then
    command = command.."get gold"..sp.."open "..goldPack..sp.."put gold in "..goldPack..sp.."close "..goldPack..sp
  elseif ataxiaTemp.goldinhand then
    command = command.."open "..goldPack..sp.."put gold in "..goldPack..sp.."close "..goldPack..sp
  end
	if ataxiaBasher.nicator and not haveDef("nicatorlegend") then command = command.."legenddeck draw nicator"..sp end

  -- Blood Maiden cloak: activate bloodshield on 4+ targetable mobs or bosses
  -- After first activation, cloak stays active for 3 minutes (free re-activations)
  if ataxiaBasher.bloodMaiden and (ataxiaTemp.bloodshieldReady or ataxiaTemp.bloodshieldActive) then
    local area = gmcp.Room.Info and gmcp.Room.Info.area
    local targets = area and ataxiaBasher.targetList[area]
    local targetCount = 0
    local hasBoss = false
    local bosses = ataxiaBasher.bloodMaidenBosses or {}
    for _, name in pairs(ataxia.denizensHere) do
      if targets then
        for mobKey, mobVal in pairs(targets) do
          local mobName = type(mobKey) == "number" and mobVal or mobKey
          if type(mobName) == "string" and mobName ~= "keyword" and name:lower() == mobName:lower() then
            targetCount = targetCount + 1
            break
          end
        end
      end
      if bosses[name] then hasBoss = true end
    end
    local threshold = ataxiaTemp.bloodshieldActive and 3 or 4
    if targetCount >= threshold or hasBoss then
      command = command.."activate bloodshield"..sp
      if ataxiaTemp.bloodshieldReady and not ataxiaTemp.bloodshieldActive then
        ataxiaTemp.bloodshieldActive = true
        ataxiaTemp.bloodshieldTimer = tempTimer(180, function()
          ataxiaTemp.bloodshieldActive = nil
          ataxiaTemp.bloodshieldTimer = nil
        end)
      end
      ataxiaTemp.bloodshieldReady = nil
    end
  end

  if not ataxiaTemp.bashFlee and not ataxia.afflictions.paralysis and not ataxia.afflictions.aeon and not ataxia.afflictions.peace and not ataxia.afflictions.transfixation and not ataxia.afflictions.webbed and not ataxia.afflictions.impaled and not ataxia.afflictions.constricted and not ataxia.afflictions.deepsleep and not ataxia.afflictions.entangled and not ataxia.afflictions.unconsciousness and not ataxia.afflictions.snared then
    command = command.._G[ataxiaBasher_bashingFuncs[class]]()
    send("queue addclearfull freestand stand"..sp..command)
	
  end
	  
end

-- Per-class special rage thresholds for the standard battlerage pattern
-- Classes not listed here use unique logic handled below
ataxiaBasher_specialRageThresholds = {
  ["Blue Dragon"] = 16,
  Bard = 28,
  Runewarden = 28,
  Infernal = 21,
  Pariah = 32,
  Blademaster = 26,
  Magi = 35,
  Serpent = 28,
  Apostate = 32,
  Monk = 22,
}

-- Generic battlerage handler for the standard pattern:
-- With 2+ targets: try special → small → large
-- With <2 targets: try small → large
local function ataxiaBasher_standardBattlerage(class, specialRage, level, sp)
  local command = ""
  local brData = ataxiaBasher.battlerage[class]
  if not brData then return "" end

  if ataxiaBasher_validTargets() >= 2 then
    if not battleRage_Timers.special and ataxia.vitals.rage >= specialRage then
      command = brData.special..sp
    elseif not battleRage_Timers.small and ataxia.vitals.rage >= 14 and battleRage_Timers.special then
      command = brData.small..sp
    elseif not battleRage_Timers.large and ataxia.vitals.rage >= 36 and battleRage_Timers.special and level > 35 then
      command = brData.large..sp
    end
  else
    if not battleRage_Timers.small and ataxia.vitals.rage >= 14 then
      command = brData.small..sp
    elseif not battleRage_Timers.large and ataxia.vitals.rage >= 36 and level > 35 then
      command = brData.large..sp
    end
  end
  return command
end

-- Crowd-control battlerage for 3+ targets (Black Dragon dragonfear, Shaman invoke korkma)
local function ataxiaBasher_crowdControlBattlerage(class, specialCmd, level, sp, smallRage, bigRage)
  local command = ""
  local brData = ataxiaBasher.battlerage[class]
  if not brData then return "" end

  if #stormhammerTargets >= 3 then
    if not battleRage_Timers.special and ataxia.vitals.rage >= 29 then
      command = specialCmd..sp
    elseif not battleRage_Timers.small and ataxia.vitals.rage >= 14 and battleRage_Timers.special then
      command = brData.small..sp
    elseif not battleRage_Timers.large and ataxia.vitals.rage >= 36 and battleRage_Timers.special and level > 35 then
      command = brData.large..sp
    end
  else
    if not battleRage_Timers.small and ataxia.vitals.rage >= smallRage then
      command = brData.small..sp
    elseif not battleRage_Timers.large and ataxia.vitals.rage >= bigRage and level > 35 then
      command = brData.large..sp
    end
  end
  return command
end

function ataxiaBasher_assembleBattlerage()
	local command = ""
	local class = gmcp.Char.Status.class:title():gsub(" Lady", ""):gsub(" Lord", "")
	local level = tonumber(string.match(gmcp.Char.Status.level, "%d+ "))
	local sp = ataxia.settings.separator

	local bigRage = (ataxiaBasher.rageraze and 54 or 36)
	local smallRage = (ataxiaBasher.rageraze and 34 or 16)

	-- Mob health-based rage conservation: skip rage abilities if mob is nearly dead
	-- Set ataxiaBasher.rageConserveThreshold (e.g., 15) to enable.
	-- Culling Blade (reap) is exempt since it's a finisher.
	if ataxiaBasher.rageConserveThreshold then
		local mobhp = tonumber((gmcp.IRE.Target.Info.hpperc or "100"):gsub("%%", "")) or 100
		if mobhp > 0 and mobhp <= ataxiaBasher.rageConserveThreshold then
			return ""
		end
	end

	-- Culling Blade check (applies before any class-specific logic)
	if ataxiaBasher.cullingBlade and not ataxiaTemp.bladeCooldown
		and gmcp.Room.Info.area ~= "the Fathomless Expanse of the World Tree" then
		if ataxia.vitals.rage >= bigRage then
			command = command.."reap "..target..sp
		end
	-- Psion: unique logic — special requires mobhealth >= 40, rage >= 40, and small NOT on CD; large at 25 rage
	elseif gmcp.Char.Status.class == "Psion" then
		local mobhp = tonumber((gmcp.IRE.Target.Info.hpperc or "0"):gsub("%%", "")) or 0
		local brData = ataxiaBasher.battlerage[class]
		if brData then
			if not battleRage_Timers.special and mobhp >= 40 and ataxia.vitals.rage >= 40 and not battleRage_Timers.small then
				command = brData.special..sp
			elseif not battleRage_Timers.small and ataxia.vitals.rage >= 14 and battleRage_Timers.special then
				command = brData.small..sp
			elseif not battleRage_Timers.large and ataxia.vitals.rage >= 25 and battleRage_Timers.special and level > 35 then
				command = brData.large..sp
			end
		end
	-- Black Dragon: dragonfear on 3rd target when 3+ mobs present
	elseif gmcp.Char.Status.class == "Black Dragon" then
		local specialCmd = " dragonfear "..(stormhammerTargets[3] or target)
		command = ataxiaBasher_crowdControlBattlerage(class, specialCmd, level, sp, smallRage, bigRage)
	-- Shaman: invoke korkma on 3rd target when 3+ mobs present
	elseif gmcp.Char.Status.class == "Shaman" then
		local specialCmd = " invoke korkma "..(stormhammerTargets[3] or target)
		command = ataxiaBasher_crowdControlBattlerage(class, specialCmd, level, sp, smallRage, bigRage)
	-- Standard pattern: check if class has a known specialRage threshold
	elseif ataxiaBasher_specialRageThresholds[class] then
		command = ataxiaBasher_standardBattlerage(class, ataxiaBasher_specialRageThresholds[class], level, sp)
	-- Fallback for unknown classes: just use small/large
	elseif ataxiaBasher.battlerage[class] then
		if not battleRage_Timers.small and ataxia.vitals.rage >= smallRage then
			command = ataxiaBasher.battlerage[class].small..sp
		elseif not battleRage_Timers.large and ataxia.vitals.rage >= bigRage and level > 35 then
			command = ataxiaBasher.battlerage[class].large..sp
		end
	end
	return command
end