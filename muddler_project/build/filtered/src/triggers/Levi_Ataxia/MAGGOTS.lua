if isTargeted(matches[2]) then
	tarAffed(matches[3])
	if applyAffV3 then applyAffV3(matches[3]) end
  tarAffedConfirmed(matches[3])
  if applyAffV3 then applyAffV3(matches[3]) end
   confirmAffV2(matches[3])
 if partyrelay then send("pt "..target..": "..matches[3])
      end
end
