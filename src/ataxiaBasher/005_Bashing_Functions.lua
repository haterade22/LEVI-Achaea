-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Ataxia-DownloadThis > Basher > Bashing > Bashing Functions

function ataxiaBasher_attack()

	ataxiaBasher_bashingFuncs = {}
	ataxiaBasher_bashingFuncs = {
    --Elementals
  	["Air Elemental"] = _G.ataxiaBasher_aEleBashing,
		["Fire Elemental"] = _G.ataxiaBasher_fEleBashing,
    ["Water Elemental"] = _G.ataxiaBasher_wEleBashing, 
    ["Earth Elemental"] = _G.ataxiaBasher_eEleBashing,
    --Dragons
		["Blue Dragon"] = _G.ataxiaBasher_dragonBashing,
		["Black Dragon"] = _G.ataxiaBasher_dragonBashing,
    ["Green Dragon"] = _G.ataxiaBasher_dragonBashing,
    ["Golden Dragon"] = _G.ataxiaBasher_dragonBashing,
    ["Red Dragon"] = _G.ataxiaBasher_dragonBashing,
    ["Silver Dragon"] = _G.ataxiaBasher_dragonBashing,
    --Standard Classes
    Alchemist = _G.ataxiaBasher_alchemistBashing,
		Apostate = _G.ataxiaBasher_apostateBashing,
		Bard = _G.ataxiaBasher_bardBashing,
		Blademaster = _G.ataxiaBasher_blademasterBashing,
		Depthswalker = _G.ataxiaBasher_depthswalkerBashing,
    Infernal = _G.ataxiaBasher_infernalBashing,
		Jester = _G.ataxiaBasher_jesterBashing,
		Magi = _G.ataxiaBasher_magiBashing,
		Monk = _G.ataxiaBasher_monkBashing2,
		Occultist = _G.ataxiaBasher_occultistBashing,
    Paladin = _G.ataxiaBasher_paladinBashing,
    Pariah = _G.ataxiaBasher_pariahBashing,
		Priest = _G.ataxiaBasher_priestBashing,
		Psion = _G.ataxiaBasher_psionBashing,
		Runewarden = _G.ataxiaBasher_runewardenBashing,
		Sentinel = _G.ataxiaBasher_sentinelBashing,
		Serpent = _G.ataxiaBasher_serpentBashing,
		Shaman = _G.ataxiaBasher_shamanBashing,   
		Sylvan = _G.ataxiaBasher_sylvanBashing,
    Unnamable = _G.ataxiaBasher_knightBashing,
	}
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
        expandAlias("goto " ..mmp.previousroom) 
		  if ataxia.vitals.hp >= ataxia.vitals.maxhp then
			  ataxiaTemp.bashFlee = false
        ataxiaBasher.paused = false
			  search_targets()
			   if not found_target and ataxiaTemp.bashFlee == true then	
				  ataxiaEcho("Healed to threshold, moving back to v"..mmp.previousroom..".")
          ataxiaTemp.bashFlee = false
          ataxiaBasher.paused = false
          if mmp.paused then mmp.pause("off") end
          expandAlias("goto " ..mmp.previousroom)
          search_targets() 
			   end
			  ataxiaBasher_patterns()
        ataxiagui_updateVitals()
      elseif ataxia.vitals.hp <= ataxiaBasher.fleeThreshold then
        ataxiaTemp.bashFlee = true
        ataxiaBasher.paused = true
        ataxiaEcho("BASH FLEE IS TRUE/PAUSING BASHER/GETTING TO FULL HEALTH")
        ataxiagui_updateVitals()
      end
    elseif gmcp.Room.Info.area == "Moghedu" and ataxia.playersHere == "Hikagejuunin" then
      guardianofmogcunts = true
      ataxiaBasher_areaoff()
      ataxiaBasher.pause = true
      expandAlias("mstop")
      send("cq all")
      expandAlias("goto Mhaldor")
   
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
	if ataxiaTemp.goldInRoom then 
    command = command.."get gold"..sp.."open pack436363"..sp.."put gold in pack436363"..sp.."close pack436363"..sp
  elseif ataxiaTemp.goldinhand then
    command = command.."open pack436363"..sp.."put gold in pack436363"..sp.."close pack436363"..sp
  end
	if ataxiaBasher.nicator and not haveDef("nicatorlegend") then command = command.."legenddeck draw nicator"..sp end
 
  if ataxiaTemp.bashFlee == false and not ataxia.afflictions.paralysis and not ataxia.afflictions.aeon and not ataxia.afflictions.peace then
    command = command..ataxiaBasher_bashingFuncs[class]()
    send("queue addclearfull freestand stand"..sp..command)	
	
  end
	  
end

function ataxiaBasher_assembleBattlerage()
	local command = ""
	local class = gmcp.Char.Status.class:title():gsub(" Lady", ""):gsub(" Lord", "")
	local level = tonumber(string.match(gmcp.Char.Status.level, "%d+ "))
	
	local bigRage = (ataxiaBasher.rageraze and 54 or 36)
	local smallRage = (ataxiaBasher.rageraze and 34 or 16)
  local specialRage = 25
	
	if ataxiaBasher.cullingBlade and not ataxiaTemp.bladeCooldown and ataxiaBasher_validTargets() >= 2 then
		if ataxia.vitals.rage >= bigRage then
			command = command.."reap "..target..ataxia.settings.separator
		end
  elseif gmcp.Char.Status.class == "Blue Dragon" then
    
   mobhealth = gmcp.IRE.Target.Info.hpperc:gsub("%%", "")
   mobhealth = tonumber(mobhealth)
    if ataxiaBasher_validTargets() >= 2 then
    if not battleRage_Timers.special and ataxia.vitals.rage >= 16 then
      command = command..ataxiaBasher.battlerage[class].special..ataxia.settings.separator
    elseif not battleRage_Timers.small and ataxia.vitals.rage >= 14 and battleRage_Timers.special then
		  command = command..ataxiaBasher.battlerage[class].small..ataxia.settings.separator
    elseif not battleRage_Timers.large and ataxia.vitals.rage >= 36 and battleRage_Timers.special and level > 35 then
	   command = command..ataxiaBasher.battlerage[class].large..ataxia.settings.separator
    end
  elseif ataxiaBasher_validTargets() < 2 then 
    if not battleRage_Timers.small and ataxia.vitals.rage >= 14 then
		  command = command..ataxiaBasher.battlerage[class].small..ataxia.settings.separator
    elseif not battleRage_Timers.large and ataxia.vitals.rage >= 36 and level > 35 then
	   command = command..ataxiaBasher.battlerage[class].large..ataxia.settings.separator
    end
  end
  
  elseif gmcp.Char.Status.class == "Bard" then
   mobhealth = gmcp.IRE.Target.Info.hpperc:gsub("%%", "")
   mobhealth = tonumber(mobhealth)
  if ataxiaBasher_validTargets() >= 2 then
    if not battleRage_Timers.special and ataxia.vitals.rage >= 28 then
      command = command..ataxiaBasher.battlerage[class].special..ataxia.settings.separator
    elseif not battleRage_Timers.small and ataxia.vitals.rage >= 14 and battleRage_Timers.special then
		  command = command..ataxiaBasher.battlerage[class].small..ataxia.settings.separator
    elseif not battleRage_Timers.large and ataxia.vitals.rage >= 36 and battleRage_Timers.special and level > 35 then
	   command = command..ataxiaBasher.battlerage[class].large..ataxia.settings.separator
    end
  elseif ataxiaBasher_validTargets() < 2 then 
    if not battleRage_Timers.small and ataxia.vitals.rage >= 14 then
		  command = command..ataxiaBasher.battlerage[class].small..ataxia.settings.separator
    elseif not battleRage_Timers.large and ataxia.vitals.rage >= 36 and level > 35 then
	   command = command..ataxiaBasher.battlerage[class].large..ataxia.settings.separator
    end
  end
  elseif gmcp.Char.Status.class == "Psion" then
    
   mobhealth = gmcp.IRE.Target.Info.hpperc:gsub("%%", "")
   mobhealth = tonumber(mobhealth)
    if not battleRage_Timers.special and mobhealth >= 40 and ataxia.vitals.rage >= 40 and not battleRage_Timers.small then
      command = command..ataxiaBasher.battlerage[class].special..ataxia.settings.separator
    elseif not battleRage_Timers.small and ataxia.vitals.rage >= 14 and battleRage_Timers.special then
		  command = command..ataxiaBasher.battlerage[class].small..ataxia.settings.separator
    elseif not battleRage_Timers.large and ataxia.vitals.rage >= 25 and battleRage_Timers.special and level > 35 then
	   command = command..ataxiaBasher.battlerage[class].large..ataxia.settings.separator
    end
  elseif gmcp.Char.Status.class == "Runewarden" then
   mobhealth = gmcp.IRE.Target.Info.hpperc:gsub("%%", "")
   mobhealth = tonumber(mobhealth)
    if ataxiaBasher_validTargets() >= 2 then
      if not battleRage_Timers.special and ataxia.vitals.rage >= 28 then
        command = command..ataxiaBasher.battlerage[class].special..ataxia.settings.separator
      elseif not battleRage_Timers.small and ataxia.vitals.rage >= 14 and battleRage_Timers.special then
		    command = command..ataxiaBasher.battlerage[class].small..ataxia.settings.separator
      elseif not battleRage_Timers.large and ataxia.vitals.rage >= 36 and battleRage_Timers.special and level > 35 then
	     command = command..ataxiaBasher.battlerage[class].large..ataxia.settings.separator
      end
    elseif ataxiaBasher_validTargets() < 2 then 
      if not battleRage_Timers.small and ataxia.vitals.rage >= 14 then
		    command = command..ataxiaBasher.battlerage[class].small..ataxia.settings.separator
      elseif not battleRage_Timers.large and ataxia.vitals.rage >= 36 and level > 35 then
	     command = command..ataxiaBasher.battlerage[class].large..ataxia.settings.separator
      end
  end
  elseif gmcp.Char.Status.class == "Infernal" then
   mobhealth = gmcp.IRE.Target.Info.hpperc:gsub("%%", "")
   mobhealth = tonumber(mobhealth)
   if ataxiaBasher_validTargets() >= 2 then
    if not battleRage_Timers.special and ataxia.vitals.rage >= 21 then
      command = command..ataxiaBasher.battlerage[class].special..ataxia.settings.separator
    elseif not battleRage_Timers.small and ataxia.vitals.rage >= 14 and battleRage_Timers.special then
		  command = command..ataxiaBasher.battlerage[class].small..ataxia.settings.separator
    elseif not battleRage_Timers.large and ataxia.vitals.rage >= 36 and battleRage_Timers.special and level > 35 then
	   command = command..ataxiaBasher.battlerage[class].large..ataxia.settings.separator
    end
  elseif ataxiaBasher_validTargets() < 2 then 
    if not battleRage_Timers.small and ataxia.vitals.rage >= 14 then
		  command = command..ataxiaBasher.battlerage[class].small..ataxia.settings.separator
    elseif not battleRage_Timers.large and ataxia.vitals.rage >= 36 and level > 35 then
	   command = command..ataxiaBasher.battlerage[class].large..ataxia.settings.separator
    end
  end
  elseif gmcp.Char.Status.class == "Pariah" then
   mobhealth = gmcp.IRE.Target.Info.hpperc:gsub("%%", "")
   mobhealth = tonumber(mobhealth)
    if ataxiaBasher_validTargets() >= 2 then
    if not battleRage_Timers.special and ataxia.vitals.rage >= 32 then
      command = command..ataxiaBasher.battlerage[class].special..ataxia.settings.separator
    elseif not battleRage_Timers.small and ataxia.vitals.rage >= 14 and battleRage_Timers.special then
		  command = command..ataxiaBasher.battlerage[class].small..ataxia.settings.separator
    elseif not battleRage_Timers.large and ataxia.vitals.rage >= 36 and battleRage_Timers.special and level > 35 then
	   command = command..ataxiaBasher.battlerage[class].large..ataxia.settings.separator
    end
  elseif ataxiaBasher_validTargets() < 2 then 
    if not battleRage_Timers.small and ataxia.vitals.rage >= 14 then
		  command = command..ataxiaBasher.battlerage[class].small..ataxia.settings.separator
    elseif not battleRage_Timers.large and ataxia.vitals.rage >= 36 and level > 35 then
	   command = command..ataxiaBasher.battlerage[class].large..ataxia.settings.separator
    end
  end
  elseif gmcp.Char.Status.class == "Blademaster" then
   mobhealth = gmcp.IRE.Target.Info.hpperc:gsub("%%", "")
   mobhealth = tonumber(mobhealth)
   if ataxiaBasher_validTargets() >= 2 then
    if not battleRage_Timers.special and ataxia.vitals.rage >= 26 then
      command = command..ataxiaBasher.battlerage[class].special..ataxia.settings.separator
    elseif not battleRage_Timers.small and ataxia.vitals.rage >= 14 and battleRage_Timers.special then
		  command = command..ataxiaBasher.battlerage[class].small..ataxia.settings.separator
    elseif not battleRage_Timers.large and ataxia.vitals.rage >= 36 and battleRage_Timers.special and level > 35 then
	   command = command..ataxiaBasher.battlerage[class].large..ataxia.settings.separator
    end
  elseif ataxiaBasher_validTargets() < 2 then 
    if not battleRage_Timers.small and ataxia.vitals.rage >= 14 then
		  command = command..ataxiaBasher.battlerage[class].small..ataxia.settings.separator
    elseif not battleRage_Timers.large and ataxia.vitals.rage >= 36 and level > 35 then
	   command = command..ataxiaBasher.battlerage[class].large..ataxia.settings.separator
    end
  end
  elseif gmcp.Char.Status.class == "Magi" then
   mobhealth = gmcp.IRE.Target.Info.hpperc:gsub("%%", "")
   mobhealth = tonumber(mobhealth)
  if ataxiaBasher_validTargets() >= 2 then
    if not battleRage_Timers.special and ataxia.vitals.rage >= 35 then
      command = command..ataxiaBasher.battlerage[class].special..ataxia.settings.separator
    elseif not battleRage_Timers.small and ataxia.vitals.rage >= 14 and battleRage_Timers.special then
		  command = command..ataxiaBasher.battlerage[class].small..ataxia.settings.separator
    elseif not battleRage_Timers.large and ataxia.vitals.rage >= 36 and battleRage_Timers.special and level > 35 then
	   command = command..ataxiaBasher.battlerage[class].large..ataxia.settings.separator
    end
  elseif ataxiaBasher_validTargets() < 2 then 
    if not battleRage_Timers.small and ataxia.vitals.rage >= 14 then
		  command = command..ataxiaBasher.battlerage[class].small..ataxia.settings.separator
    elseif not battleRage_Timers.large and ataxia.vitals.rage >= 36 and level > 35 then
	   command = command..ataxiaBasher.battlerage[class].large..ataxia.settings.separator
    end
  end
  elseif gmcp.Char.Status.class == "Serpent" then
   mobhealth = gmcp.IRE.Target.Info.hpperc:gsub("%%", "")
   mobhealth = tonumber(mobhealth)
  if ataxiaBasher_validTargets() >= 2 then
    if not battleRage_Timers.special and ataxia.vitals.rage >= 28 then
      command = command..ataxiaBasher.battlerage[class].special..ataxia.settings.separator
    elseif not battleRage_Timers.small and ataxia.vitals.rage >= 14 and battleRage_Timers.special then
		  command = command..ataxiaBasher.battlerage[class].small..ataxia.settings.separator
    elseif not battleRage_Timers.large and ataxia.vitals.rage >= 36 and battleRage_Timers.special and level > 35 then
	   command = command..ataxiaBasher.battlerage[class].large..ataxia.settings.separator
    end
  elseif ataxiaBasher_validTargets() < 2 then 
    if not battleRage_Timers.small and ataxia.vitals.rage >= 14 then
		  command = command..ataxiaBasher.battlerage[class].small..ataxia.settings.separator
    elseif not battleRage_Timers.large and ataxia.vitals.rage >= 36 and level > 35 then
	   command = command..ataxiaBasher.battlerage[class].large..ataxia.settings.separator
    end
  end
  elseif gmcp.Char.Status.class == "Apostate" then
   mobhealth = gmcp.IRE.Target.Info.hpperc:gsub("%%", "")
   mobhealth = tonumber(mobhealth)
   if ataxiaBasher_validTargets() >= 2 then
    if not battleRage_Timers.special and ataxia.vitals.rage >= 32 then
      command = command..ataxiaBasher.battlerage[class].special..ataxia.settings.separator
    elseif not battleRage_Timers.small and ataxia.vitals.rage >= 14 and battleRage_Timers.special then
		  command = command..ataxiaBasher.battlerage[class].small..ataxia.settings.separator
    elseif not battleRage_Timers.large and ataxia.vitals.rage >= 36 and battleRage_Timers.special and level > 35 then
	   command = command..ataxiaBasher.battlerage[class].large..ataxia.settings.separator
    end
  elseif ataxiaBasher_validTargets() < 2 then 
    if not battleRage_Timers.small and ataxia.vitals.rage >= 14 then
		  command = command..ataxiaBasher.battlerage[class].small..ataxia.settings.separator
    elseif not battleRage_Timers.large and ataxia.vitals.rage >= 36 and level > 35 then
	   command = command..ataxiaBasher.battlerage[class].large..ataxia.settings.separator
    end
  end
  elseif gmcp.Char.Status.class == "Monk" then
   mobhealth = gmcp.IRE.Target.Info.hpperc:gsub("%%", "")
   mobhealth = tonumber(mobhealth)
 if ataxiaBasher_validTargets() >= 2 then
    if not battleRage_Timers.special and ataxia.vitals.rage >= 22 then
      command = command..ataxiaBasher.battlerage[class].special..ataxia.settings.separator
    elseif not battleRage_Timers.small and ataxia.vitals.rage >= 14 and battleRage_Timers.special then
		  command = command..ataxiaBasher.battlerage[class].small..ataxia.settings.separator
    elseif not battleRage_Timers.large and ataxia.vitals.rage >= 36 and battleRage_Timers.special and level > 35 then
	   command = command..ataxiaBasher.battlerage[class].large..ataxia.settings.separator
    end
  elseif ataxiaBasher_validTargets() < 2 then 
    if not battleRage_Timers.small and ataxia.vitals.rage >= 14 then
		  command = command..ataxiaBasher.battlerage[class].small..ataxia.settings.separator
    elseif not battleRage_Timers.large and ataxia.vitals.rage >= 36 and level > 35 then
	   command = command..ataxiaBasher.battlerage[class].large..ataxia.settings.separator
    end
  end
   elseif gmcp.Char.Status.class == "Black Dragon" then
   mobhealth = gmcp.IRE.Target.Info.hpperc:gsub("%%", "")
   mobhealth = tonumber(mobhealth)
    if #stormhammerTargets >= 3 then -- If there are more than two targets than Fear the third
      if not battleRage_Timers.special and ataxia.vitals.rage >= 29  then
        command = command.." dragonfear " ..stormhammerTargets[3]..ataxia.settings.separator
      elseif not battleRage_Timers.small and ataxia.vitals.rage >= 14 and battleRage_Timers.special then
		    command = command..ataxiaBasher.battlerage[class].small..ataxia.settings.separator
      elseif not battleRage_Timers.large and ataxia.vitals.rage >= 36 and battleRage_Timers.special and level > 35 then
	       command = command..ataxiaBasher.battlerage[class].large..ataxia.settings.separator
      end
    elseif #stormhammerTargets < 3 then
      if not battleRage_Timers.small and ataxia.vitals.rage >= smallRage then
		    command = command..ataxiaBasher.battlerage[class].small..ataxia.settings.separator
	    elseif not battleRage_Timers.large and ataxia.vitals.rage >= bigRage and level > 35 then
		    command = command..ataxiaBasher.battlerage[class].large..ataxia.settings.separator
      end
    end
  elseif gmcp.Char.Status.class == "Shaman" then
   mobhealth = gmcp.IRE.Target.Info.hpperc:gsub("%%", "")
   mobhealth = tonumber(mobhealth)
    --[[if #stormhammerTargets >= 1 then
      if not battleRage_Timers.special2 and ataxia.vitals.rage >= 19  then
        command = command..ataxiaBasher.battlerage[class].special2..ataxia.settings.separator
      elseif not battleRage_Timers.small and ataxia.vitals.rage >= 14 and battleRage_Timers.special2 then
		    command = command..ataxiaBasher.battlerage[class].small..ataxia.settings.separator
      elseif not battleRage_Timers.large and ataxia.vitals.rage >= 36 and battleRage_Timers.special2 and level > 35 then
	       command = command..ataxiaBasher.battlerage[class].large..ataxia.settings.separator
      end
    elseif]]
    if #stormhammerTargets >= 3 then -- If there are more than two targets than Fear the third
      if not battleRage_Timers.special and ataxia.vitals.rage >= 29  then
        command = command.." invoke korkma " ..stormhammerTargets[3]..ataxia.settings.separator
      elseif not battleRage_Timers.small and ataxia.vitals.rage >= 14 and battleRage_Timers.special then
		    command = command..ataxiaBasher.battlerage[class].small..ataxia.settings.separator
      elseif not battleRage_Timers.large and ataxia.vitals.rage >= 36 and battleRage_Timers.special and level > 35 then
	       command = command..ataxiaBasher.battlerage[class].large..ataxia.settings.separator
      end
    elseif #stormhammerTargets < 3 then
      if not battleRage_Timers.small and ataxia.vitals.rage >= smallRage then
		    command = command..ataxiaBasher.battlerage[class].small..ataxia.settings.separator
	    elseif not battleRage_Timers.large and ataxia.vitals.rage >= bigRage and level > 35 then
		    command = command..ataxiaBasher.battlerage[class].large..ataxia.settings.separator
      end
    end
  elseif not battleRage_Timers.small and ataxia.vitals.rage >= smallRage then
		command = command..ataxiaBasher.battlerage[class].small..ataxia.settings.separator
	elseif not battleRage_Timers.large and ataxia.vitals.rage >= bigRage and level > 35 then
		command = command..ataxiaBasher.battlerage[class].large..ataxia.settings.separator
	end
	return command
end