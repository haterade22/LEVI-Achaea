if isTargeted(matches[2]) and not ataxiaTemp.ignoreShield then
	if haveAff("prone") then
		moveCursor(0, getLineNumber())
		tarAffed("blackout")
		if applyAffV3 then applyAffV3("blackout") end
		moveCursorEnd()
		tempTimer(3.5, [[erAff("blackout"); if removeAffV3 then removeAffV3("blackout") end]])
      if partyrelay and not ataxia.afflictions.aeon then send("pt "..target..": blackout")
      end
	end
end

tinvest = false