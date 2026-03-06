if not affs_to_colour then populate_aff_colours() end

-- Guard: envenomList may be nil or empty (e.g., when using timeloop)
local aff = nil
if envenomList and envenomList[1] then
    aff = venom_to_aff(envenomList[1])
end

if type(target) ~= "number" and isTargeted(matches[2]) then
    if aff then
        tarAffed(aff)
        if applyAffV3 then applyAffV3(aff) end
    end
    targetIshere = true
    disableTimer("TargetOutOfRoom")
end
	if haveAff("timeloop") then
		checkTimeloop = false
		enableTrigger("Timeloop Failsafe Update")
	end



--if type(target) ~= "number" and isTargeted(matches[2]) then	
 -- send("assess "..target..(ataxia.settings.separator or "::").."contemplate "..target)--end