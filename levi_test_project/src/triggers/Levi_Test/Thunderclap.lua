if isTargeted(matches[2]) then
	if sylvan_overcharge then
		tarBonusAff("paralysis")
	end
	tarAffed("sensitivity")
	if applyAffV3 then applyAffV3("sensitivity") end
end