if isTargeted(matches[3]) and not ataxiaTemp.ignoreShield then
	moveCursor(0, getLineNumber())
	tarAffed("prone")
	moveCursorEnd()
   if partyrelay then send("pt "..target..": prone")
      end
end
ataxiaTemp.ignoreShield = nil