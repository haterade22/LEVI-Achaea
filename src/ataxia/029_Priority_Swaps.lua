-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Ataxia-DownloadThis > Ataxia > System-related > Curing Stuff > Priority-related > Swaps > Priority Swaps

--scyPara functions
function ataxia_swapScyPara(event, affliction)
  if not ataxia.prioritySwaps then ataxia_resetSwaps() end
	if not ataxia.prioritySwaps.scyPara.active then return end
  if event == "aff gained" then
		if affliction == "scytherus" and affed("paralysis") and ataxia_getPrio("scytherus") ~= 2 then
			ataxia_setAffPrio("scytherus", 2)
		end
  end
end

function ataxia_restoreScyPara(event, affliction)
  if not ataxia.prioritySwaps then ataxia_resetSwaps() end
	if not ataxia.prioritySwaps.scyPara.active then return end
	if event == "aff cured" then
		if affliction == "scytherus" and ataxia_getPrio("scytherus") ~= ataxia_defaultPrioAff("scytherus") then
			ataxia_restorePrio("scytherus")
		end
	end
end
registerAnonymousEventHandler("aff gained", "ataxia_swapScyPara")
registerAnonymousEventHandler("aff cured", "ataxia_restoreScyPara")

--conDis functions
function ataxia_swapConDis(event, affliction)
  if not ataxia.prioritySwaps then ataxia_resetSwaps() end
	if not ataxia.prioritySwaps.conDis.active then return end
	if event == "aff gained" then
		if affed("confusion") and affed("disrupted") and affed("impatience") and not affed("whisperingmadness") and ataxia_getPrio("confusion") ~= 2 then
			ataxia_setAffPrio("confusion", 2)
		end
	end
end

function sentinel_swaphaemophilia(event, affliction)
  if not ataxia.prioritySwaps then ataxia_resetSwaps() end
	if event == "aff gained" then
		if target == "Andraste" and affed("haemophilia") then
			ataxia_setAffPrio("haemophilia", 6)
		end
	end
end

function ataxia_restoreConDis(event, affliction)
  if not ataxia.prioritySwaps then ataxia_resetSwaps() end
	if not ataxia.prioritySwaps.conDis.active then return end
	if event == "aff cured" then
		if affliction == "confusion" and ataxia_getPrio("confusion") ~= ataxia_defaultPrioAff("confusion") then
			ataxia_restorePrio("confusion")
		end
	end
end
registerAnonymousEventHandler("aff gained", "ataxia_swapConDis")
registerAnonymousEventHandler("aff cured", "ataxia_restoreConDis")

--astImp functions
function ataxia_swapAstImp(event, affliction)
  if not ataxia.prioritySwaps then ataxia_resetSwaps() end
	if not ataxia.prioritySwaps.astImp.active then return end
	if not ataxiaNDB_Exists(target) then return end
	if event == "aff gained" then
		if affed("paralysis") and affed("asthma") and (ataxiaNDB_getClass(target) == "Alchemist" or ataxiaNDB_getClass(target) == "Serpent") and ataxia_getPrio("impatience") ~= 1 then
			ataxia_setAffPrio("impatience", 1)
		end
	end
end

function ataxia_swapWATER(event, affliction)
  if not ataxia.prioritySwaps then ataxia_resetSwaps() end
	if not ataxia.prioritySwaps.WATER.active then return end
	if not ataxiaNDB_Exists(target) then return end
	if event == "aff gained" then
		if affed("nausea") and (affed("asthma") or affed("weariness")) and (ataxiaNDB_getClass(target) == "Blademaster") then
			ataxia_setAffPrio("nausea", 1)
		end
	end
end
		
function ataxia_restoreAstImp(event, affliction)
  if not ataxia.prioritySwaps then ataxia_resetSwaps() end
	if not ataxia.prioritySwaps.astImp.active then return end
	if not ataxiaNDB_Exists(target) then return end
	if event == "aff cured" then
		if (ataxia_defaultPrioAff("impatience") ~= ataxia_getPrio("impatience")) and not (affed("paralysis") and affed("asthma")) then
			ataxia_restorePrio("impatience")
		end
	end
end
registerAnonymousEventHandler("aff gained", "ataxia_swapAstImp")
registerAnonymousEventHandler("aff cured", "ataxia_restoreAstImp")

--brSlick functions
function ataxia_swapBrSlick(event, affliction)
  if not ataxia.prioritySwaps then ataxia_resetSwaps() end
	if not ataxia.prioritySwaps.brSlick.active then return end
	if event == "aff gained" then
		if (affed("sensitivity") or affed("clumsiness") or affed("weariness") or affed("hypochondria")) and affed("asthma") and affed("slickness") and not affed("anorexia") and ataxia_getPrio("slickness") ~= 1 then 
			ataxia_setAffPrio("slickness", 1)
		end
	end
end

function ataxia_restoreBrSlick(event, affliction)
  if not ataxia.prioritySwaps then ataxia_resetSwaps() end
	if not ataxia.prioritySwaps.brSlick.active then return end
  if event == "aff cured" then
    if (ataxia_defaultPrioAff("slickness") ~= ataxia_getPrio("slickness")) and not affed("asthma") and not (affed("sensitivity") or affed("clumsiness") or affed("weariness") or affed("hypochondria")) then
      ataxia_restorePrio("slickness")
    end
  end
end 
registerAnonymousEventHandler("aff gained", "ataxia_swapBrSlick")
registerAnonymousEventHandler("aff cured", "ataxia_restoreBrSlick")

--hypoImp functions
function ataxia_swapHypoImp(event, affliction)
  if not ataxia.prioritySwaps then ataxia_resetSwaps() end
	if not ataxia.prioritySwaps.hypoImp.active then return end
  if event == "aff gained" then
    if (affed("lethargy") or affed("nausea") or affed("addiction")) and affed("hypochondria") and ataxia_getPrio("hypochondria") ~= 1 then
			ataxia_setAffPrio("impatience", 4)
			ataxia_setAffPrio("hypochondria", 1)
    end
  end
end

function ataxia_restoreHypoImp(event, affliction)
  if not ataxia.prioritySwaps then ataxia_resetSwaps() end
	if not ataxia.prioritySwaps.hypoImp.active then return end
  if event == "aff cured" then
    if affliction == "hypochondria" then
			ataxia_restorePrio("hypochondria")
			ataxia_restorePrio("impatience")
		end
  end
end
registerAnonymousEventHandler("aff gained", "ataxia_swapHypoImp")
registerAnonymousEventHandler("aff cured", "ataxia_restoreHypoImp")

--Darkshade functions
function ataxia_swapDarkshade(event, affliction)
  if not ataxia.prioritySwaps then ataxia_resetSwaps() end
	if not ataxia.prioritySwaps.dShade.active then return end
  if event == "aff gained" and affliction == "darkshade" then
    if ataxia.lightwall then
			if ataxia_getPrio("darkshade") > 3 then
				ataxia_setAffPrio("darkshade", 3 )
			end
			ataxia_darkshadeTimer(true)
    else
      ataxia_darkshadeTimer(false)
    end
  end
end

function ataxia_restoreDarkshade(event, affliction)
  if not ataxia.prioritySwaps then ataxia_resetSwaps() end
	if not ataxia.prioritySwaps.dShade.active then return end
  if event == "aff cured" then
    if affliction == "darkshade" then
			if ataxia_getPrio("darkshade") ~= ataxia_defaultPrioAff("darkshade") then
      	ataxia_restorePrio("darkshade")
			end
		end
		if ataxiaTemp.darkshadeTimer then killTimer(tostring(ataxiaTemp.darkshadeTimer)) end
		ataxiaTemp.darkshadeTimer = nil
  end
end
registerAnonymousEventHandler("aff gained", "ataxia_swapDarkshade")
registerAnonymousEventHandler("aff cured", "ataxia_restoreDarkshade")


function ataxia_darkshadeTimer(set)
  if ataxiaTemp.darkshadeTimer then killTimer(tostring(ataxiaTemp.darkshadeTimer)) end
  if ataxia.lightwall then
    ataxiaTemp.darkshadeTimer = tempTimer(15, [[ataxiaTemp.darkshadeTimer = nil; send("curing prioaff darkshade")]])

  else
    ataxiaTemp.darkshadeTimer = tempTimer(50, [[ataxiaTemp.darkshadeTimer = nil; send("curing prioaff darkshade")]])
  end
end

function ataxia_ravagedMindSwap(event, affliction)
  if not ataxia.prioritySwaps then ataxia_resetSwaps() end
	if not ataxia.prioritySwaps.ravaged or affliction ~= "mindravaged" then return end
	if event == "aff gained" and ataxia.settings.priohealth then
		send("curing priority mana",false)
	elseif event == "aff cured" then
		send("curing priority health",false)
	end
end
registerAnonymousEventHandler("aff gained", "ataxia_ravagedMindSwap")
registerAnonymousEventHandler("aff cured", "ataxia_ravagedMindSwap")
