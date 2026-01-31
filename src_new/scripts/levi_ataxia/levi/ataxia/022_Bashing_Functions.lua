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

	local class = gmcp.Char.Status.class:title()
  class = class:gsub(" Lady", ""):gsub(" Lord", "")
  if ataxiaTemp.bashFlee == nil then
    ataxiaTemp.bashFlee = false
  end
  --Make a Magi Reflection Function
if not ataxia.afflictions.aeon and not ataxia.afflictions.paralysis and not ataxia.afflictions.peace then
    if ataxiaTemp.bashFlee == true then
      ataxiaBasher.paused = true
      ataxiaEcho("BASH FLEE IS TRUE/PAUSING BASHER/RUNNING BACK ONE ROOM")
      send("cq all")
      if mmp.paused then mmp.pause("off") end
      if mmp.previousroom then
        expandAlias("goto " ..mmp.previousroom)
      else
        ataxiaEcho("No previous room to flee to - shielding instead.")
        send("touch shield")
      end
		  if ataxia.vitals.hp >= ataxia.vitals.maxhp then
			  ataxiaTemp.bashFlee = false
        ataxiaBasher.paused = false
        -- Cancel flee circuit breaker since we recovered
        if ataxiaTemp.fleeCircuitBreaker then killTimer(ataxiaTemp.fleeCircuitBreaker); ataxiaTemp.fleeCircuitBreaker = nil end
			  search_targets()
			   if not found_target and ataxiaTemp.bashFlee == true then
          if mmp.previousroom then
				    ataxiaEcho("Healed to threshold, moving back to v"..mmp.previousroom..".")
            ataxiaTemp.bashFlee = false
            ataxiaBasher.paused = false
            if mmp.paused then mmp.pause("off") end
            expandAlias("goto " ..mmp.previousroom)
            search_targets()
          end
			   end
			  ataxiaBasher_patterns()
        ataxiagui_updateVitals()
      elseif ataxia.vitals.hp <= ataxiaBasher.fleeThreshold then
        ataxiaTemp.bashFlee = true
        ataxiaBasher.paused = true
        ataxiaEcho("BASH FLEE IS TRUE/PAUSING BASHER/GETTING TO FULL HEALTH")
        ataxiagui_updateVitals()
      end
    elseif ataxia.vitals.hp <= ataxiaBasher.fleeThreshold then
        ataxiaTemp.bashFlee = true
        ataxiaBasher.paused = true
        ataxiaBasher_startFleeTimer()
        send("cq all")
        if mmp.paused then mmp.pause("off") end
        if mmp.previousroom then
          expandAlias("goto " ..mmp.previousroom)
        else
          ataxiaEcho("No previous room to flee to - shielding instead.")
          send("touch shield")
        end
        ataxiagui_updateVitals()
    elseif ataxiaBasher.fleeFromPlayers and ataxiaBasher.fleeFromPlayers[gmcp.Room.Info.area] then
      -- Configurable per-area player flee: check if any hostile player matches the flee list
      local shouldFlee = false
      if type(ataxia.playersHere) == "table" then
        for _, player in pairs(ataxia.playersHere) do
          if table.contains(ataxiaBasher.fleeFromPlayers[gmcp.Room.Info.area], player) then
            shouldFlee = true
            break
          end
        end
      end
      if shouldFlee then
        ataxiaBasher_areaoff()
        ataxiaBasher.paused = true
        expandAlias("mstop")
        send("cq all")
        send("touch shield")
        ataxiaEcho("Hostile player detected in area! Fleeing and disabling basher.")
      end
   
		elseif ataxia.afflictions.unknown and ataxia.afflictions.unknown >= 2 and not sent_diagnose then
			send("queue addclear freestand diagnose", false)
			sent_diagnose = tempTimer(3, [[sent_diagnose = nil]])
		elseif ataxiaBasher.noShieldBreak.threshold > 0 and ataxia.vitals.hp < ataxiaBasher.noShieldBreak.threshold and ataxiaBasher_canShield() then
			if not ataxia.defences.shield then
				ataxiaEcho("Going to shield on balance!")
				send("queue addclear freestand touch shield")
			end
		elseif ataxia.defences.shield and ataxiaBasher_bashingFuncs[class] and canStand() then
			if ataxia.vitals.hpp >= 70 then
				ataxiaBasher_assembleAttack()
			end
		elseif ataxiaBasher_bashingFuncs[class] and canStand() then
			ataxiaBasher_assembleAttack()
		elseif not ataxiaBasher_bashingFuncs[class] and canStand() then
			ataxiaEcho(class.." isn't supported yet, sorry!")
		end
	end
   ataxiaBasher_stormhammer()  
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
  ataxiaBasher_stormhammer()
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
	if ataxiaBasher.cullingBlade and not ataxiaTemp.bladeCooldown and ataxiaBasher_validTargets() >= 2 then
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