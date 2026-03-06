if not ataxiaTemp.ignoreShield then
	moveCursor(0, getLineNumber())
	if not tAffs.healthleech then tarAffed("healthleech"); if applyAffV3 then applyAffV3("healthleech") end elseif tAffs.healthleech then
  tarAffed("confusion"); if applyAffV3 then applyAffV3("confusion") end end
   if partyrelay then send("pt "..target..": healthleech")
   elseif partyrelay and tAffs.healthleech then send("pt "..target..": confusion")
  
  end
	moveCursorEnd()
end
ataxiaTemp.ignoreShield = nil

tinvest = true