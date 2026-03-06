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
	-- Damage tracking is now handled by the regex trigger in Track_The_Damage.lua
	-- which captures actual damage percentages from the game message
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
	-- Damage tracking is now handled by the regex trigger in Track_The_Damage.lua
	-- which captures actual damage percentages from the game message
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
	-- Damage tracking is now handled by the regex trigger in Track_The_Damage.lua
	-- which captures actual damage percentages from the game message
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
	-- Damage tracking is now handled by the regex trigger in Track_The_Damage.lua
	-- which captures actual damage percentages from the game message
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
	-- Damage tracking is now handled by the regex trigger in Track_The_Damage.lua
	-- which captures actual damage percentages from the game message
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
	-- Damage tracking is now handled by the regex trigger in Track_The_Damage.lua
	-- which captures actual damage percentages from the game message
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
	-- Damage tracking is now handled by the regex trigger in Track_The_Damage.lua
	-- which captures actual damage percentages from the game message
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
	-- Damage tracking is now handled by the regex trigger in Track_The_Damage.lua
	-- which captures actual damage percentages from the game message
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
	-- Damage tracking is now handled by the regex trigger in Track_The_Damage.lua
	-- which captures actual damage percentages from the game message
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
	-- Damage tracking is now handled by the regex trigger in Track_The_Damage.lua
	-- which captures actual damage percentages from the game message
end
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
