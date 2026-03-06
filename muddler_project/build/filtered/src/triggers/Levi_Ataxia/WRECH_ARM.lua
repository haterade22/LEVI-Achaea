if isTargeted(matches[3]) and not ataxiaTemp.ignoreShield then
	moveCursor(0, getLineNumber())
	tarAffed("prone")
	if applyAffV3 then applyAffV3("prone") end
	moveCursorEnd()
   if partyrelay then send("pt "..target..": prone")
      end
end
ataxiaTemp.ignoreShield = nil