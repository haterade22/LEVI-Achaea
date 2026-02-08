if isTargeted(matches[2]) then
	tarAffed(matches[3])
	if applyAffV3 then applyAffV3(matches[3]) end
	send("contemplate "..target,false)
end