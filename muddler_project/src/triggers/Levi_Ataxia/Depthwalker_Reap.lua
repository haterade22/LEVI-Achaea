if not affs_to_colour then populate_aff_colours() end


local aff = venom_to_aff(envenomList[1])

if type(target) ~= "number" and isTargeted(matches[2]) then
	tarAffed(aff)
	targetIshere = true
	disableTimer("TargetOutOfRoom")
end
	if haveAff("timeloop") then
		checkTimeloop = false
		enableTrigger("Timeloop Failsafe Update")
	end



--if type(target) ~= "number" and isTargeted(matches[2]) then	
 -- send("assess "..target..(ataxia.settings.separator or "::").."contemplate "..target)--end