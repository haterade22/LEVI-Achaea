if isTargeted(matches[2]) then
	tarAffedConfirmed("paralysis")
  if ataxia.settings.raid.enabled then
    send("pt paralysis on "..matches[2],false)
  end
end