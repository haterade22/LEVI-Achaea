if isTargeted(matches[2]) and not ataxiaTemp.ignoreShield then
	local smashAffs = {"dizziness", "recklessness", "stupidity", "confusion", "epilepsy"}
	for i=1, #smashAffs do
		if not haveAff(smashAffs[i]) then
			moveCursor(0, getLineNumber())
			tarAffed(smashAffs[i])
			moveCursorEnd()
			break
		end
       if partyrelay then send("pt "..target..": "..smashAffs[i])
      end
	end
end
ataxiaTemp.ignoreShield = nil


tinvest = false