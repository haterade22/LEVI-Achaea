if isTargeted(matches[2]) then
	ataxiaTemp.relapseAff = curseConvert(matches[3])
	
	tarAffed(ataxiaTemp.relapseAff)
   if partyrelay then send("pt "..target..": "..ataxiaTemp.relapseAff) end
	ataxiaTemp.relapseAff = nil
end