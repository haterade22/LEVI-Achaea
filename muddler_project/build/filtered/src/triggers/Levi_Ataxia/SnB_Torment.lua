if not ataxiaTemp.ignoreShield then
	moveCursor(0, getLineNumber())
	if not tAffs.healthleech then tarAffed("healthleech") elseif tAffs.healthleech then
  tarAffed("confusion")end
   if partyrelay then send("pt "..target..": healthleech")
   elseif partyrelay and tAffs.healthleech then send("pt "..target..": confusion")
  
  end
	moveCursorEnd()
end
ataxiaTemp.ignoreShield = nil

tinvest = true