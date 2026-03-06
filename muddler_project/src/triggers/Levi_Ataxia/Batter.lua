if isTargeted(matches[2]) then
	tarAffed("stupidity", "epilepsy", "dizziness")
	if applyAffV3 then applyAffV3("stupidity"); applyAffV3("epilepsy"); applyAffV3("dizziness") end
  battered = true
  tempTimer(15, [[battered = false]])
  if partyrelay then
    send("pt "..matches[2]..": stupidity epilepsy dizziness")
  end
end