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
  if ataxia.defences.shield then
    if ataxia.vitals.hpp >= 70 and ataxiaBasher_bashingFuncs[class] and canStand() then
      ataxiaBasher_assembleAttack()
    end
  elseif ataxiaBasher_bashingFuncs[class] and canStand() then
    ataxiaBasher_assembleAttack()
  elseif not ataxiaBasher_bashingFuncs[class] and canStand() then
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

  local fleePct = ataxiaBasher.fleeThresholdPct or 25
  if hpp <= fleePct then return "flee" end

  if ataxiaBasher_isDamageRateExtreme() then
    ataxiaEcho("DANGER: Extreme incoming damage rate detected! Fleeing.")
    return "flee"
  end

  local shieldPct = ataxiaBasher.shieldThresholdPct or 40
  if hpp <= shieldPct and ataxiaBasher_canShield and ataxiaBasher_canShield() and not ataxia.defences.shield then
    return "shield"
  end

  return "attack"
end

-- ============================================================================
-- Flee execution with movement validation
-- ============================================================================
function ataxiaBasher_executeFlee()
  ataxiaTemp.bashFlee = true
  ataxiaBasher.paused = true
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

  if mmp.previousroom then
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
  local recoveryPct = ataxiaBasher.fleeRecoveryPct or 70

  if (ataxia.vitals.hpp or 0) >= recoveryPct then
    ataxiaTemp.bashFlee = false
    ataxiaBasher.paused = false
    if ataxiaTemp.fleeCircuitBreaker then
      killTimer(ataxiaTemp.fleeCircuitBreaker)
      ataxiaTemp.fleeCircuitBreaker = nil
    end
    ataxiaEcho("HP recovered to " .. math.floor(ataxia.vitals.hpp) .. "%. Resuming bashing.")
    search_targets()
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
  -- Wand of Reflection emergency check
  if not ataxia.wandReflectionThreshold then ataxia.wandReflectionThreshold = 10 end
  if not ataxia.wandReflectionRecovery then ataxia.wandReflectionRecovery = 70 end

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
    send("cq all;point wand234800 at me")
    ataxia.wandReflectionActive = true
    ataxia.wandReflectionCooldown = true
    tempTimer(3600, [[ataxia.wandReflectionCooldown = false]])  -- 1 hour cooldown (wand is hourly)
    ataxiaEcho("EMERGENCY: HP below 10%! Using wand of reflection, pausing until 70% HP.")
    return  -- Skip attack this cycle
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

  -- Blood Maiden cloak: activate bloodshield based on mob count or specific mobs
  -- 4+ mobs anywhere, 3+ elite mhun keepers in Moghedu, Azdun bosses, or fighting Rhuzios
  if ataxiaTemp.bloodshieldReady then
    local mobCount = 0
    local keeperCount = 0
    local hasBoss = false
    for _, name in pairs(ataxia.denizensHere) do
      mobCount = mobCount + 1
      if name == "an elite mhun keeper" then keeperCount = keeperCount + 1 end
      if name == "Rhuzios, the Mummy Lord"
        or name == "Underlord Seroth"
        or name == "Underlord Dreyvos" then hasBoss = true end
    end
    local inMoghedu = gmcp.Room.Info and gmcp.Room.Info.area == "Moghedu"
    if mobCount >= 4 or (inMoghedu and keeperCount >= 3) or hasBoss then
      command = command.."activate bloodshield"..sp
      ataxiaTemp.bloodshieldReady = nil
    end
  end

  if ataxiaTemp.bashFlee == false and not ataxia.afflictions.paralysis and not ataxia.afflictions.aeon and not ataxia.afflictions.peace then
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
	if ataxiaBasher.cullingBlade and not ataxiaTemp.bladeCooldown then
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