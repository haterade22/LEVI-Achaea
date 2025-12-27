--[[mudlet
type: script
name: Different Attacks
hierarchy:
- Levi_Ataxia
- LEVI
- Ataxia
- Ataxia
- System-related
- Self Limb Tracking
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

------------------------------------------------------------------------------------------------------------------------
--> Blademaster
--[armslash]--
function armslash_selfLimbhit(side)
	selectString(side, 1)
	setBold(true)
	fg("a_blue")
	resetFormat()
	deselect()
	
	tempLineTrigger(1, 1, [[confirm_armslash("]]..side..[[")]])
end

function confirm_armslash(side)
	if not ataxiaTables.missLines then resetMissLines() end
	local parry = false
	for _, part in pairs(ataxiaTables.missLines) do
		if line:match(part) then
			parry = true
			break
		end
	end
	
	if not parry then confirmed_armslash(side) end
end

function confirmed_armslash(side)
	if not ataxiaTemp.blademasterDamage then resetBladeMasterDamage() end
	if side == "left" then
		ataxia_raiseLimbDamage("right arm", ataxiaTemp.blademasterDamage.off)
		ataxia_raiseLimbDamage("left arm", ataxiaTemp.blademasterDamage.slash)
	else
		ataxia_raiseLimbDamage("left arm", ataxiaTemp.blademasterDamage.off)
		ataxia_raiseLimbDamage("right arm", ataxiaTemp.blademasterDamage.slash)
	end
end
--[legslash]--
function legslash_selfLimbhit(side)
	selectString(side, 1)
	setBold(true)
	fg("a_blue")
	resetFormat()
	deselect()
	
	tempLineTrigger(1, 1, [[confirm_legslash("]]..side..[[")]])
end

function confirm_legslash(side)
	if not ataxiaTables.missLines then resetMissLines() end
	local parry = false
	for _, part in pairs(ataxiaTables.missLines) do
		if line:match(part) then
			parry = true
			break
		end
	end
	
	if not parry then confirmed_legslash(side) end
end

function confirmed_legslash(side)
	if not ataxiaTemp.blademasterDamage then resetBladeMasterDamage() end
	if side == "left" then
		ataxia_raiseLimbDamage("right leg", ataxiaTemp.blademasterDamage.off)
		ataxia_raiseLimbDamage("left leg", ataxiaTemp.blademasterDamage.slash)
	else
		ataxia_raiseLimbDamage("left leg", ataxiaTemp.blademasterDamage.off)
		ataxia_raiseLimbDamage("right leg", ataxiaTemp.blademasterDamage.slash)
	end
end
--[centreslash]--
function centreslash_selfLimbhit(section)
	selectString(section, 1)
	setBold(true)
	fg("a_blue")
	resetFormat()
	deselect()
	
	tempLineTrigger(1, 1, [[confirm_centreslash("]]..section..[[")]])
end

function confirm_centreslash(section)
	if not ataxiaTables.missLines then resetMissLines() end
	local parry = false
	for _, part in pairs(ataxiaTables.missLines) do
		if line:match(part) then
			parry = true
			break
		end
	end
	
	if not parry then confirmed_centreslash(section) end
end

function confirmed_centreslash(section)
	if not ataxiaTemp.blademasterDamage then resetBladeMasterDamage() end
	if section == "torso" then
		ataxia_raiseLimbDamage("head", ataxiaTemp.blademasterDamage.off)
		ataxia_raiseLimbDamage("torso", ataxiaTemp.blademasterDamage.slash)
	else
		ataxia_raiseLimbDamage("torso", ataxiaTemp.blademasterDamage.off)
		ataxia_raiseLimbDamage("head", ataxiaTemp.blademasterDamage.slash)
	end
end
------------------------------------------------------------------------------------------------------------------------
--> Earth Lord
function earthLord_selfLimbHit(limb)
	selectString(limb, 1)
	setBold(true)
	fg("a_blue")
	resetFormat()
	deselect()
	
	tempLineTrigger(1, 1, [[earthLord_confirmHit("]]..limb..[[")]])
end

function earthLord_confirmHit(limb)
	if not ataxiaTables.missLines then resetMissLines() end
	local parry = false
	for _, part in pairs(ataxiaTables.missLines) do
		if line:match(part) then
			parry = true
			break
		end
	end
	
	if not parry then ataxia_raiseLimbDamage(limb, 16.7) end
end
------------------------------------------------------------------------------------------------------------------------
--> Knight (WIP)
function snb_selfLimbHit(limb)
	selectString(limb, 1)
	setBold(true)
	fg("a_blue")
	resetFormat()
	deselect()
	
	tempLineTrigger(1, 1, [[confirm_snbhit("]]..limb..[[")]])
end

function confirm_snbhit(limb)
	if not ataxiaTables.missLines then resetMissLines() end
	if not ataxiaTemp.knightDamage then resetKnightDamage() end
	local parry = false
	for _, part in pairs(ataxiaTables.missLines) do
		if line:match(part) then
			parry = true
			break
		end
	end
	
	if not parry then ataxia_raiseLimbDamage(limb, ataxiaTemp.knightDamage.snb) end
end

function dwc_selfLimbHit(limb)
	selectString(limb, 1)
	setBold(true)
	fg("a_blue")
	resetFormat()
	deselect()
	
	tempLineTrigger(1, 1, [[confirm_dwchit("]]..limb..[[")]])
end

function confirm_dwchit(limb)
	if not ataxiaTables.missLines then resetMissLines() end
	if not ataxiaTemp.knightDamage then resetKnightDamage() end
	local parry = false
	for _, part in pairs(ataxiaTables.missLines) do
		if line:match(part) then
			parry = true
			break
		end
	end
	
	if not parry then ataxia_raiseLimbDamage(limb, ataxiaTemp.knightDamage.dwc) end
end

------------------------------------------------------------------------------------------------------------------------
--> Priest (basic for now, just as something to work with)
function priest_selfLimbHit(limb)
  selectString(limb,1)
  setBold(true)
  fg("a_blue")
  resetFormat()
  deselect()
  
  tempLineTrigger(1, 1, [[confirm_limbsmite("]]..limb..[[")]])
end

function confirm_limbsmite(limb)
	if not ataxiaTables.missLines then resetMissLines() end
	local parry = false
	for _, part in pairs(ataxiaTables.missLines) do
		if line:match(part) then
			parry = true
			break
		end
	end
	
	if not parry then ataxia_raiseLimbDamage(limb, 15.8) end
end  

------------------------------------------------------------------------------------------------------------------------
--> Dragon/Druid (quarter)

function quarterHit_selfLimbHit(limb)
	selectString(limb, 1)
	setBold(true)
	fg("a_blue")
	resetFormat()
	deselect()
	
	tempLineTrigger(1, 1, [[confirm_quarterHit("]]..limb..[[")]])
end

function confirm_quarterHit(limb)
	if not ataxiaTables.missLines then resetMissLines() end
	local parry = false
	for _, part in pairs(ataxiaTables.missLines) do
		if line:match(part) then
			parry = true
			break
		end
	end
	
	if not parry then ataxia_raiseLimbDamage(limb, 25) end
end
------------------------------------------------------------------------------------------------------------------------
--> Magi

function staffStrike_selfLimbHit(element, limb)
	selectString(limb, 1)
	setBold(true)
	fg("a_blue")
	resetFormat()
	deselect()
	
	tempLineTrigger(1, 1, [[confirm_staffStrike("]]..element..[[","]]..limb..[[")]])
end

function confirm_staffStrike(element, limb)
	if not ataxiaTables.missLines then resetMissLines() end
	local parry = false
	for _, part in pairs(ataxiaTables.missLines) do
		if line:match(part) then
			parry = true
			break
		end
	end
	
	if not parry then confirmed_staffStrike(element, limb) end
end

function confirmed_staffStrike(element, limb)
	local health = ataxia.vitals.maxhp
	local sd, ad
	if health <= 3499 then
		sd = string.format("%2.2f", (100/6.5))
	elseif health <= 6700 then
		sd = string.format("%2.2f", (100/6.5))
	else
		sd = string.format("%2.2f", (100/7))
	end
	ad = string.format("%2.2f", (100/12))

	if element == "Whirrh" then
		ataxia_raiseLimbDamage(limb, ad)
	else
		ataxia_raiseLimbDamage(limb, sd)
	end
end
------------------------------------------------------------------------------------------------------------------------
--> Sylvan

function thornrend_selfLimbHit(limb)
	selectString(limb, 1)
	setBold(true)
	fg("a_blue")
	resetFormat()
	deselect()
	
	tempLineTrigger(1, 1, [[confirm_thornrend("]]..limb..[[")]])
end

function confirm_thornrend(limb)
	if not ataxiaTables.missLines then resetMissLines() end
	local parry = false
	for _, part in pairs(ataxiaTables.missLines) do
		if line:match(part) then
			parry = true
			break
		end
	end
	
	if not parry then 
		if affed("vinewreathed") then
			ataxia_raiseLimbDamage(limb, 12.5)
		else
			ataxia_raiseLimbDamage(limb, 25)
		end
	end
end
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
