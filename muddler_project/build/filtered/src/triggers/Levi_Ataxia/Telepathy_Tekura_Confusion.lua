if isTargeted(matches[2]) then
	tarAffedConfirmed("confusion")
  if ataxia.settings.raid.enabled then
    if partyrelay and not ataxia.afflictions.aeon then
    send("pt confusion on "..matches[2],false)
    end
  end
end