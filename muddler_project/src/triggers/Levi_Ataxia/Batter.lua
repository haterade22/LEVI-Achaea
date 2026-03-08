if isTargeted(matches[2]) then
	tarAffed("stupidity", "epilepsy", "dizziness")
  battered = true
  tempTimer(15, [[battered = false]])
  if partyrelay then
    send("pt "..matches[2]..": stupidity epilepsy dizziness")
  end
end