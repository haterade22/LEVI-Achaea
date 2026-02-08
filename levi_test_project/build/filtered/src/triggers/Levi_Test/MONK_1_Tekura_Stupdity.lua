if isTargeted(matches[2]) then
	tarAffedConfirmed("stupidity")
	if applyAffV3 then applyAffV3("stupidity") end
  if ataxia.settings.raid.enabled then
    send("pt stupidity on "..matches[2],false)
  end
end