if isTargeted(matches[2]) then
	if sylvan_overcharge then
		tarAffed("paralysis")
		if applyAffV3 then applyAffV3("paralysis") end
	end
	tAffs.deafness = false
	if removeAffV3 then removeAffV3("deafness") end
end