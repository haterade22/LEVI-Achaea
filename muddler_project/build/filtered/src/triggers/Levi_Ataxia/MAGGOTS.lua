if isTargeted(matches[2]) then
	tarAffed(matches[3])
  tarAffedConfirmed(matches[3])
   confirmAffV2(matches[3])
 if partyrelay then send("pt "..target..": "..matches[3])
      end
end
