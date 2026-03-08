if isTargeted(matches[2]) then
	tarAffed("impatience")
  impatiencemind = true
  tempTimer(3, [[impatiencemind = false]])
  if partyrelay then
    send("pt "..matches[2]..": impatience",false)
  end
end