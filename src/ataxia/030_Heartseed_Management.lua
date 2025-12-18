-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Ataxia-DownloadThis > Ataxia > System-related > Curing Stuff > Priority-related > Swaps > Heartseed Management

--Borrowed from wundersys, and cleaned up to be more readible.
--Couldn't be bothered figuring it out, myself.
ataxiaTemp.heartseedMode = ataxiaTemp.heartseedMode or nil
local fakeApply = fakeApply or false

--For handling automatic fake applies. Probably more reliable than manualling it for most people.
function ataxia_heartseedMendCheck(event, aff)
	local affl = {"brokenrightleg", "brokenleftleg", "brokenrightarm", "brokenleftarm"}
	if event == "aff cured" and ataxiaTemp.heartseedMode then
		if table.contains(affl, aff) then
			fakeApply = true
			if ataxiaTables.limbTimers.fakeApplyTimer then killTimer(ataxiaTables.limbTimers.fakeApplyTimer); ataxiaTables.limbTimers.fakeApplyTimer = nil end
			ataxiaTables.limbTimers.fakeApplyTimer = tempTimer(1.9, [[fakeApply = false; ataxiaTables.limbTimers.fakeApplyTimer = nil]])
		end
	end
end

--Will apply fake, in an attempt to bait the Sylvan to heartseed.			
function ataxia_heartseedFake()
	if ataxiaTemp.heartseedMode and fakeApply then
		if not affed("heartseed") then
			if affed("damagedrightleg") or affed("damagedleftleg") then
				send("apply mass to legs")
			elseif affed("damagedleftarm") or affed("damagedrightarm") then
				send("apply mass to arms")
			end
		end
		fakeApply = false
	end
end
	
--Turn limb curing off if our target is a Sylvan
function ataxia_heartseedDisable(event, aff)
	local affl = {"damagedleftleg", "damagedrightleg", "damagedleftarm", "damagedrightarm"}
	if event == "aff gained" and ataxiaTemp.heartseedMode and ataxiaNDB_getClass(target) == "Sylvan" then
		if table.contains(affl, aff) then
      ataxia_setAffPrio("damagedleftleg", 26)
      ataxia_setAffPrio("damagedrightleg", 26)
      ataxia_setAffPrio("mangledleftleg", 26)
      ataxia_setAffPrio("mangledrightleg", 26)
      ataxia_setAffPrio("damagedleftarm", 26)
      ataxia_setAffPrio("damagedrightarm", 26)
      ataxia_setAffPrio("mangledleftarm", 26)
      ataxia_setAffPrio("mangledrightarm", 26)
		end
	end		
end
registerAnonymousEventHandler("aff gained", "ataxia_heartseedDisable")

--Turn limb curing back on.
function ataxia_heartseedCured(event, aff)
	if event == "aff cured" and aff == "heartseed" then
		if ataxiaTemp.heartseedMode and ( affed("damagedleftleg") or affed("damagedrightleg") ) then
			ataxia_restorePrio("damagedleftleg")
			ataxia_restorePrio("damagedrightleg")
			ataxia_restorePrio("mangledleftleg")
			ataxia_restorePrio("mangledrightleg")
			ataxia_restorePrio("damagedleftarm")
			ataxia_restorePrio("damagedrightarm")
			ataxia_restorePrio("mangledleftarm")
			ataxia_restorePrio("mangledrightarm")
		end
	end
end

registerAnonymousEventHandler("aff cured", "ataxia_heartseedCured")