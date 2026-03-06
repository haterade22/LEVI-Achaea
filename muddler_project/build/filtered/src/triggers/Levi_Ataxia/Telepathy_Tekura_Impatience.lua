if isTargeted(matches[2]) then
	tarAffed("impatience")
	if applyAffV3 then applyAffV3("impatience") end
  if ataxia.settings.raid.enabled then
    send("pt "..matches[2]..": impatience",false)
  end
end