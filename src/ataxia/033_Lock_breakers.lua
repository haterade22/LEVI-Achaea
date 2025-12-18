-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Ataxia-DownloadThis > Ataxia > System-related > Curing Stuff > Can(x) > Lock breakers

--Will return true if venom locked.
function ataxia_needLockBreak()
	if affed("asthma") and affed("anorexia") and (affed("slickness") or affed("bloodfire")) and gmcp.Char.Status.class ~= "Psion" then
		return true
  elseif affed("asthma") and affed("anorexia") and (affed("slickness") or affed("bloodfire")) and affed("impatience") and gmcp.Char.Status.class == "Psion" then
		return true
	elseif affed("whisperingmadness") then
  return true
  	elseif affed("slime") then
  return true
  else
		return false
	end
end

--If we can break the venom lock, then do so. Requires eq/bal.
function ataxia_lockBreak()

		if ataxia_needLockBreak() then
			if ataxia_canActive() and not ataxiaTemp.activeCureUsed and not attemptedLockBreak then
				attemptedLockBreak = tempTimer(1.5, [[ attemptedLockBreak = nil ]])
				ataxia_breakLock()
			end
		end
	end


function ataxia_canActive()
	if ataxiaTemp.activeCureUsed then return false end

	local blockers = {
		Alchemist = {"stupidity"},
		Blademaster = {"weariness"},
		Depthswalker = {"recklessness"},
		Druid = {"weariness"},
		Infernal = {"weariness"},
		Jester = {"paralysis"},
		Magi = {"haemophilia"},
		Monk = {"weariness"},
		Occultist = {"paralysis"},
		Paladin = {"weariness"},
		Runewarden = {"weariness"},
		Sentinel = {"weariness"},
		Serpent = {"weariness"},
		Shaman = {"selarnia"},
	}
	if affed("brokenleftarm") and affed("brokenrightarm") and blockers[ataxiaTemp.class] and blockers[ataxiaTemp.class][1] ~= "weariness" then
		return false
	elseif not blockers[ataxiaTemp.class] then
		if string.find(ataxiaTemp.class, "Dragon") then
			if affed("weariness") and affed("recklessness") then
				return false
			else
				return true
			end
    elseif string.find(ataxiaTemp.class, "Elemental") then
      if affed("weariness") then
        return true
      else
        return false
      end
		else
			return false
		end
	elseif affed( blockers[ataxiaTemp.class][1] ) then
		return false
	else
		return true
	end
end

function ataxia_breakLock()
	local sp = ataxia.settings.separator
	local lockBreaker = {
		Alchemist = "educe salt",
		Blademaster = "fitness",
		Depthswalker = "chrono accelerate boost",
		Druid = "fitness",
		Infernal = "fitness",
		Jester = "fling fool at me",
		Magi = "cast bloodboil",
		Monk = "fitness",
		Occultist = "fling fool at me",
		Paladin = "fitness",
    Psion = "psi expunge",
		Runewarden = "fitness",
		Sentinel = "fitness",
		Serpent = "shrugging",
		Shaman = "invoke purification",
    Unnamable = "fitness",
	}
	if affed("prone") and not affed("paralysis") then
		send("stand",false)
	end
	if string.find(ataxiaTemp.class, "Dragon") then
		send("dragonheal",false)
  elseif string.find(ataxiaTemp.class, "Earth") then
    send("terran eruption",false)
	else
		send( lockBreaker[ataxiaTemp.class], false )
	end
end

function ataxia_promptLocks()
  local lockTable = {}
  if affed("asthma") and (affed("slickness") or affed("bloodfire")) and affed("anorexia") then
    table.insert(lockTable, "soft")
    if affed("paralysis") then
      table.insert(lockTable, "venom")
    end
    if affed("impatience") or affed("sandfever") then
      table.insert(lockTable, "hard")
      if not ataxia_canActive() and affed("paralysis") then
        table.insert(lockTable, "true")
      end
    end
  end
  
  if affed("asthma") and (affed("bloodfire") or affed("slickness")) and (affed("damagedrightarm") or affed("mangledrightarm")) and (affed("damagedleftarm") or affed("mangledleftarm")) then
    table.insert(lockTable, "rift")
  end  

  if #lockTable > 0 then
    return "<NavajoWhite> (<orange>Locks: <DimGrey>"..table.concat(lockTable, ", ").."<NavajoWhite>)"
  else
    return ""
  end
end

registerAnonymousEventHandler("aff gained", "ataxia_needLockBreak")