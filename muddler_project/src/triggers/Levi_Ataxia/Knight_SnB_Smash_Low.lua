if isTargeted(matches[2]) and not ataxiaTemp.ignoreShield then
	moveCursor(0, getLineNumber())
	tarAffed("clumsiness")
	moveCursorEnd()
     if partyrelay then send("pt "..target..": clumsiness")
      end
end
ataxiaTemp.ignoreShield = nil


tinvest = false