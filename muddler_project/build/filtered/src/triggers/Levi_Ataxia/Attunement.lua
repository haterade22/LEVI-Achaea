if isTargeted(matches[2]) then
	tarAffed(matches[3])
  if partyrelay then send("pt "..target..": "..matches[3]) end
elseif isTargeted(matches[3]) then
	tarAffed(matches[2])
  if partyrelay then send("pt "..target..": "..matches[2]) end
end
