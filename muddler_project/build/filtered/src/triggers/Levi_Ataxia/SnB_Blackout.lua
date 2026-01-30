if isTargeted(matches[2]) and not ataxiaTemp.ignoreShield then
	if haveAff("prone") then
		moveCursor(0, getLineNumber())
		tarAffed("blackout")
		moveCursorEnd()
		tempTimer(3.5, [[erAff("blackout")]])
      if partyrelay and not ataxia.afflictions.aeon then send("pt "..target..": blackout")
      end
	end
end

tinvest = false