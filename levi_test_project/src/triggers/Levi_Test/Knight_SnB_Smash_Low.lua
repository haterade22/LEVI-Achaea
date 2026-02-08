if isTargeted(matches[2]) and not ataxiaTemp.ignoreShield then
	moveCursor(0, getLineNumber())
	tarAffed("clumsiness")
	if applyAffV3 then applyAffV3("clumsiness") end
	moveCursorEnd()
     if partyrelay then send("pt "..target..": clumsiness")
      end
end
ataxiaTemp.ignoreShield = nil


tinvest = false