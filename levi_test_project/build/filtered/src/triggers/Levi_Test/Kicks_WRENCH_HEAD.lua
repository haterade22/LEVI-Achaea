if isTargeted(matches[2]) and not ataxiaTemp.ignoreShield then
	moveCursor(0, getLineNumber())
	tarAffed("epilepsy")
	if applyAffV3 then applyAffV3("epilepsy") end
  
  epiparty = true
   tempTimer(30, [[epiparty = false]])
   
   if epiparty then
   tempTimer(3, [[tarAffed("epilepsy"); if applyAffV3 then applyAffV3("epilepsy") end]])
   end

	moveCursorEnd()
   if partyrelay then send("pt "..target..": epilepsy")
      end
end
ataxiaTemp.ignoreShield = nil