if isTargeted(matches[2]) and not ataxiaTemp.ignoreShield then
	moveCursor(0, getLineNumber())
	tarAffed("asthma")
	moveCursorEnd()
   if partyrelay then send("pt "..target..": asthma")
      end
end
ataxiaTemp.ignoreShield = nil

tinvest = false