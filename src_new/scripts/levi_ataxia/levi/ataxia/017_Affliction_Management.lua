--[[mudlet
type: script
name: Affliction Management
hierarchy:
- Levi_Ataxia
- LEVI
- Ataxia
- Ataxia
- Combat
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

--[[mudlet
type: script
name: Affliction Management
hierarchy:
- Levi_Ataxia
- LEVI
- Ataxia
- Ataxia
- Combat
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

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

-- pali_addPyre / pali_removePyre / pali_addBurns were DELETED in v4.7.276.
--
-- They maintained `ataxia.afflictions.pyre` / `.burning` -- our SELF counters -- but their
-- only reachable caller was tarAffed's target branch (above), so they were fed by our own
-- offence against an enemy: tarAffed("burns") fires from 492_Flamewhip and 493_Blisters,
-- both of which match OUR attack line. They also carried the only setter for
-- `ataxiaTemp.fightingPaladin` and the only call to checkDamnationThreat -- which is why
-- both were effectively dead, since no trigger in src_new applies pyre to US through
-- tarAffed.
--
-- GMCP now owns both counters (ataxia_stackAff -> setStackAff), and gotAff owns the Paladin
-- auto-detect and the Damnation alarm -- the SELF path, where a self affliction belongs.
-- See 004_Aff_gains_losses.lua.

function tarZealHit(aff)
	if not affs_to_colour then populate_aff_colours() end
	
	local cstring = "<maroon>["
	
	cstring = cstring.."<"..affs_to_colour[aff][1]..">"..affs_to_colour[aff][2]:upper()
	cstring = cstring.."<maroon>] <reset>"..target.." afflicted with "..aff.."."
	deleteLine()
	cecho("\n"..cstring)

	tAffs[aff] = true
	if applyAffV3 then applyAffV3(aff) end

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

-- DSL party relay: defers hit 1 callout and combines with hit 2 into a single line
function dslPartyRelay(affStr)
  if not partyrelay or (ataxia.afflictions and ataxia.afflictions.aeon) then return end
  if ataxiaTemp.hitCount == 1 then
    ataxiaTemp.pendingPtAff = affStr
  else
    local parts = {}
    if ataxiaTemp.pendingPtAff then table.insert(parts, ataxiaTemp.pendingPtAff) end
    table.insert(parts, affStr)
    send("pt " .. target .. ": " .. table.concat(parts, " "))
    ataxiaTemp.pendingPtAff = nil
  end
end

function erAff(what)
    -- Special numeric tracking
    if what == "haemophilia" then
        tAffs.bleed = 0
        tAffs.bleeding = 0
    elseif what == "crescendo" then
        tAffs.crescendo = 0
    else
        tAffs[what] = false
    end
    affTimers[what] = false

    -- V3 core removal (handles branching state + sync)
    if removeAffV3 then removeAffV3(what) end

    -- Repeat offence
    if ataxiaTemp and ataxiaTemp.repeatOffence and not ataxiaTemp.doRepeat then
        enableTrigger("Repeat Offence")
    end

    -- GUI updates
    if ataxiaTemp and ataxiaTemp.showingAffs then
        displayTargetAffs()
    elseif zgui then
        zgui.showTarAffs()
    end

    -- Occultist aura tracking
    if ataxiaTemp and ataxiaTemp.class == "Occultist" and readAuraAffs and readAuraAffs.count then
        readAuraAffs.count = readAuraAffs.count - 1
    end
    raiseEvent("target cured aff", what)
end

function haveAff(what)
    if haveAffV3 then return haveAffV3(what) end
    -- Ultra-fallback during load order (before V3 script loads)
    return tAffs and tAffs[what] and true or false
end

function tarAffed(...)
  local affs = arg
  local added = {}

  for _, aff in pairs(affs) do
    if type(aff) ~= "number" then
      if aff == "sensitivity" then
        if tAffs.deafness then
          tAffs.deafness = false
          if removeAffV3 then removeAffV3("deafness") end
          table.insert(added, "nodeaf")
        else
          tAffs.sensitivity = true
          if applyAffV3 then applyAffV3("sensitivity") end
          table.insert(added, "sensitivity")
          affTimers.sensitivity = getEpoch()
        end
      elseif aff == "burns" or aff == "burn" or aff == "pyre" then
        -- These used to call pali_addBurns/pali_addPyre, which write
        -- `ataxia.afflictions.burning` / `.pyre` -- OUR SELF-AFFLICTION TABLE -- from the
        -- TARGET path. Harmless while those keys were never real numbers; since v4.7.274
        -- they are the Damnation alarm's only input and the static burning4/burning5
        -- escalation reads them, so five flamewhips on an enemy would trip a kill-condition
        -- response for a burn we do not have. Routed through the normal target path now.
        local canonical = (aff == "pyre") and "pyre" or "burning"
        tAffs[canonical] = true
        if applyAffV3 then applyAffV3(canonical) end
        table.insert(added, canonical)
        affTimers[canonical] = getEpoch()
      else
        -- Core tracking: V1 cache + V3 branching state
        tAffs[aff] = true
        if applyAffV3 then applyAffV3(aff) end
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
          if removeAffV3 then removeAffV3("deafness") end
          table.insert(added, "nodeaf")
        else
          tAffs.sensitivity = true
          if applyAffV3 then applyAffV3("sensitivity") end
          table.insert(added, "sensitivity")
          affTimers.sensitivity = getEpoch()
        end
      elseif aff == "burns" or aff == "burn" then
        -- magi_addBurns() is not defined anywhere in src_new -- it survives only in a stale
        -- build artefact -- so this call THREW every time, aborting the rest of the handler.
        -- Routed through the normal target path, which is what it should always have been:
        -- applyAffV3("burning") is what maintains targetBurningLevelV3.
        tAffs.burning = true
        if applyAffV3 then applyAffV3("burning") end
      else
        tAffs[aff] = true
        if applyAffV3 then applyAffV3(aff) end
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
			if removeAffV3 then removeAffV3("deafness") end
		else
			tAffs.sensitivity = true
			if applyAffV3 then applyAffV3("sensitivity") end
		end
	elseif what == "burns" or what == "burn" then
		-- See above: magi_addBurns() has no definition in src_new and threw here too.
		tAffs.burning = true
		if applyAffV3 then applyAffV3("burning") end
	elseif not tAffs[what] then
		tAffs[what] = true
		if applyAffV3 then applyAffV3(what) end
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
			if removeAffV3 then removeAffV3("deafness") end
		else
			tAffs.sensitivity = true
			if applyAffV3 then applyAffV3("sensitivity") end
		end
	else
		tAffs[affone] = true
		if applyAffV3 then applyAffV3(affone) end
	end

	if afftwo == "sensitivity" then
		if tAffs.deafness then
			afftwo = "nodeaf"
			tAffs.deafness = false
			if removeAffV3 then removeAffV3("deafness") end
		else
			tAffs.sensitivity = true
			if applyAffV3 then applyAffV3("sensitivity") end
		end
	else
		tAffs[afftwo] = true
		if applyAffV3 then applyAffV3(afftwo) end
	end

	local affs = { affone, afftwo }
	raiseEvent("tar afflicted", affs)
	checkTargetLocks()
end

function tarTripleAff(affone, afftwo, affthree)
	if not tAffs[affone] then
		tAffs[affone] = true
		if applyAffV3 then applyAffV3(affone) end
	end
	if not tAffs[afftwo] then
		tAffs[afftwo] = true
		if applyAffV3 then applyAffV3(afftwo) end
	end
	if not tAffs[affthree] then
		tAffs[affthree] = true
		if applyAffV3 then applyAffV3(affthree) end
	end

	local affs = { affone, afftwo, affthree }
	raiseEvent("tar afflicted", affs)
	checkTargetLocks()
end

function tarBonusAff(aff)
	if not affs_to_colour then populate_aff_colours() end
	tAffs[aff] = true
	if applyAffV3 then applyAffV3(aff) end
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