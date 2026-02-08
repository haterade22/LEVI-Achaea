if isTargeted(matches[2]) and not ataxiaTemp.ignoreShield then
	moveCursor(0, getLineNumber())
	tarAffed("paralysis")
	if applyAffV3 then applyAffV3("paralysis") end
	moveCursorEnd()
   if partyrelay then send("pt "..target..": paralysis")
      end
end
ataxiaTemp.ignoreShield = nil

tinvest = false