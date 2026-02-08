if isTargeted(matches[2]) then
	tarAffed("paralysis")
	if applyAffV3 then applyAffV3("paralysis") end
  if ataxia.settings.raid.enabled then
    send("pt paralysis on "..matches[2],false)
  end
end