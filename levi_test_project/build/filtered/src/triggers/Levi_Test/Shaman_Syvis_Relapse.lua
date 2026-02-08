if isTargeted(matches[2]) then
	ataxiaTemp.relapseAff = curseConvert(matches[3])
	
	tarAffed(ataxiaTemp.relapseAff)
	if applyAffV3 then applyAffV3(ataxiaTemp.relapseAff) end
   if partyrelay then send("pt "..target..": "..ataxiaTemp.relapseAff) end
	ataxiaTemp.relapseAff = nil
end