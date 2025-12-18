-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Ataxia-DownloadThis > Ataxia > Combat > Affliction Management

function unnamableHorrorSet()
  tAffs.horror = tAffs.horror or 1
  
	local cstring = "<sienna>[<tomato>hor<NavajoWhite>"..tAffs.horror.."<sienna>] "
  cinsertText(cstring)
end

function unnamableHorrorRaise()
  tAffs.horror = tAffs.horror or 0
  tAffs.horror = tAffs.horror + 1
  
  if tAffs.horror > 5 then tAffs.horror = 5 end
  
  local hlset = ataxia.settings.affhl	
	local cstring = "<sienna>[<tomato>hor<NavajoWhite>"..tAffs.horror.."<sienna>] "
  cinsertText(cstring)
end

function unnamableHorrorLower()
  if tAffs.horror >= 3 then
    tAffs.horror = tAffs.horror - 2
  else
    tAffs.horror = tAffs.horror - 1
  end
  if tAffs.horror < 1 then
    cecho("\n<red> -= horror cured completely =-")
    tAffs.horror = nil
  else
    cecho("\n<green> -= horror at "..tAffs.horror.." =-")
  end
end

function tarZealHit(aff)
	if not affs_to_colour then populate_aff_colours() end
	
	local cstring = "<maroon>["
	
	cstring = cstring.."<"..affs_to_colour[aff][1]..">"..affs_to_colour[aff][2]:upper()
	cstring = cstring.."<maroon>] <reset>"..target.." afflicted with "..aff.."."
	deleteLine()
	cecho("\n"..cstring)

	tAffs[aff] = true
	
	if ataxiaTemp.showingAffs then
		displayTargetAffs()
	end
end

function tarGained(event, affList )
	if not affs_to_colour then populate_aff_colours() end
  local hlset = ataxia.settings.affhl	
	local cstring = ""
	
	if event == "tar afflicted" then
		for num, aff in pairs(affList) do
			if affs_to_colour[aff] then
				cstring = cstring.."<"..affs_to_colour[aff][1]..">"..affs_to_colour[aff][2]:upper()
			else
				cstring = cstring.."<white>"..string.sub(aff, 1, 3):upper()
			end
			if num ~= #affList then cstring = cstring.."<maroon>|" end
		end
    
    if hlset == "default" then
      cstring = "<maroon>["..cstring.."<maroon>] "
    elseif hlset == "bar" then
      cstring = cstring.."| "
    else
      cstring = cstring..": "
    end
		cinsertText(cstring)
	end
	
	if ataxiaTemp.showingAffs then
		displayTargetAffs()
  elseif zgui then
    zgui.showTarAffs()
	end
end
registerAnonymousEventHandler("tar afflicted", "tarGained")

function erAff(what)
	if tAffs[what] then
    if what == "haemophilia" then
      tAffs.bleed = 0
      tAffs.bleeding = 0
    elseif what == "crescendo" then
			tAffs.crescendo = 0
	 else
		  tAffs[what] = false
    end
  affTimers[what] = false
	end

	if ataxiaTemp.repeatOffence and not ataxiaTemp.doRepeat then
		enableTrigger("Repeat Offence")
	end
	
	if ataxiaTemp.showingAffs then
		displayTargetAffs()
  elseif zgui then
    zgui.showTarAffs()
	end
	
	if ataxiaTemp.class == "Occultist" and readAuraAffs and readAuraAffs.count then
		readAuraAffs.count = readAuraAffs.count - 1
	end
  raiseEvent("target cured aff", what)	
end

function haveAff(what)
	if tAffs and tAffs[what] then
		return true
	else
		return false
	end
end

function tarAffed(...)
  local affs = arg
  local added = {}
  
  for _, aff in pairs(affs) do
    if type(aff) ~= "number" then
      if aff == "sensitivity" then
        if tAffs.deafness then
          tAffs.deafness = false
          table.insert(added, "nodeaf")
        else
          tAffs.sensitivity = true
          table.insert(added, "sensitivity")
          
          affTimers.sensitivity = getEpoch()
        end
      elseif aff == "burns" or aff == "burn" then
        pali_addBurns()
      elseif aff == "pyre" or aff == "pyre" then
        pali_addPyre()
      else
        tAffs[aff] = true
        table.insert(added, aff)
        affTimers[aff] = getEpoch()
      end
    end
  end
  if not table.contains(affs, "burn") and not table.contains(affs, "burns") then
    raiseEvent("tar afflicted", added)
    checkTargetLocks()
  end
end

function addAffList(affTable)
  if type(affTable) ~= "table" then return end
  local affs = affTable
  local added = {}
  
  for _, aff in pairs(affs) do
    if type(aff) ~= "number" then
      if aff == "sensitivity" then
        if tAffs.deafness then
          tAffs.deafness = false
          table.insert(added, "nodeaf")
        else
          tAffs.sensitivity = true
          table.insert(added, "sensitivity")
          affTimers.sensitivity = getEpoch()
        end
      elseif aff == "burns" or aff == "burn" then
        magi_addBurns()
      else
        tAffs[aff] = true
        table.insert(added, aff)
        affTimers[aff] = getEpoch()
      end
    end
  end
  if not table.contains(affs, "burn") and not table.contains(affs, "burns") then
    raiseEvent("tar afflicted", added)
    checkTargetLocks()
  end
end

function tarSingleAff(what)
	local aff = what
	if what == "sensitivity" then
		if tAffs.deafness then
			aff = "nodeaf"
			tAffs.deafness = false
		else
			tAffs.sensitivity = true
		end
	elseif what == "burns" or what == "burn" then
		magi_addBurns()
	elseif not tAffs[what] then
		tAffs[what] = true
	end
	
	if what ~= "burns" and what ~= "burn" then
		local affs = { aff }	
		raiseEvent("tar afflicted", affs)	
		checkTargetLocks()
	end
end

function tarDoubleAff(affone, afftwo)
	if not affs_to_colour then populate_aff_colours() end
	if affone == "sensitivity" then
		if tAffs.deafness then
			affone = "nodeaf"
			tAffs.deafness = false
		else
			tAffs.sensitivity = true
		end
	else
		tAffs[affone] = true
	end
	
	if afftwo == "sensitivity" then
		if tAffs.deafness then
			afftwo = "nodeaf"
			tAffs.deafness = false
		else
			tAffs.sensitivity = true
		end
	else
		tAffs[afftwo] = true
	end

	local affs = { affone, afftwo }	
	raiseEvent("tar afflicted", affs)	
	checkTargetLocks()
end

function tarTripleAff(affone, afftwo, affthree)
	if not tAffs[affone] then
		tAffs[affone] = true
	end
	if not tAffs[afftwo] then
		tAffs[afftwo] = true
	end
	if not tAffs[affthree] then
		tAffs[affthree] = true
	end

	local affs = { affone, afftwo, affthree }	
	raiseEvent("tar afflicted", affs)	
	checkTargetLocks()
end

function tarBonusAff(aff)
	if not affs_to_colour then populate_aff_colours() end
	tAffs[aff] = true
	cecho("<NavajoWhite> +<"..affs_to_colour[aff][1]..">"..affs_to_colour[aff][2]:upper().."<NavajoWhite>+")
end

function displayTargetAffs()
	ataxiagui.tarAffsConsole:clear()
	ataxiagui.tarAffsConsole:setFontSize(8)
	ataxiagui.tarAffsConsole:setWrap(36)
	
	local ignoreAffs = {"curseward", "blindness", "deafness", "rebounding", "shield"}
	local str = "<a_brown>[<NavajoWhite>"..target:title().."<a_brown>]: "
	for aff, boo in pairs(tAffs) do
		if boo ~= false and not table.contains(ignoreAffs, aff) then
			if affs_to_colour[aff] then
				str = str.."<"..affs_to_colour[aff][1]..">"..affs_to_colour[aff][2].." "
			else
				str = str.."<DimGrey>"..string.sub(aff, 1, 3).." "
			end	
		end
	end
	
	ataxiagui.tarAffsConsole:cecho(str)
end