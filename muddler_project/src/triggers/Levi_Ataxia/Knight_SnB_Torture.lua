if isTargeted(matches[2]) and not ataxiaTemp.ignoreShield then
	moveCursor(0, getLineNumber())
	tarAffed("haemophilia")
	if applyAffV3 then applyAffV3("haemophilia") end
   if partyrelay then send("pt "..target..": haemophilia")
  end
	moveCursorEnd()
end
ataxiaTemp.ignoreShield = nil