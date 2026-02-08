if isTargeted(matches[2]) and not ataxiaTemp.ignoreShield then
	moveCursor(0, getLineNumber())
	tarAffed("asthma")
	if applyAffV3 then applyAffV3("asthma") end
	moveCursorEnd()
   if partyrelay then send("pt "..target..": asthma")
      end
end
ataxiaTemp.ignoreShield = nil

tinvest = false