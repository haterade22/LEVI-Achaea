if type(target) ~= "number" and isTargeted(matches[2]) and #envenomList > 0 then
	tarAffed(envenomList[1])
	table.remove(envenomList, 1)
	targetIshere = true
	disableTimer("TargetOutOfRoom")

	if haveAff("timeloop") then
		checkTimeloop = false
		enableTrigger("Timeloop Failsafe Update")
	end
end
if type(target) ~= "number" and isTargeted(matches[2]) then	
  send("assess "..target..(ataxia.settings.separator or "::").."contemplate "..target) 
end
tcull = false