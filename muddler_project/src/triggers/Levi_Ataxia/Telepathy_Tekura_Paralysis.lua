if isTargeted(matches[2]) then
	tarAffed("paralysis")
  if ataxia.settings.raid.enabled then
    send("pt paralysis on "..matches[2],false)
  end
end