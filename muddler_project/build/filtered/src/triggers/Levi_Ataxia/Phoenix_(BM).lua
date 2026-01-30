local name = matches[2]
local class = (ataxiaNDB_getClass(name) or "Unknown")

if isTargeted(matches[2]) and class == "Blademaster" and not haveAff("prone") then
  tAffs = {blindness = false, deafness = false, shield = false, rebounding = false, curseward = false}
	-- V2 integration: Phoenix resets all afflictions
	if resetAffsV2 then resetAffsV2() end
	selectString(line,1)
	fg("NavajoWhite")
  ataxia_boxEcho("PHOENIXED! AFFS RESET", "purple")
	resetFormat()
	targetIshere = true
end