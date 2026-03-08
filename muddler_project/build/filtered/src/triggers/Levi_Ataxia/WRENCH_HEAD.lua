if isTargeted(matches[2]) and not ataxiaTemp.ignoreShield then
	moveCursor(0, getLineNumber())
	tarAffed("epilepsy")
  
  epiparty = true
   tempTimer(30, [[epiparty = false]])
   
   if epiparty then
   tempTimer(3, [[tarAffed("epilepsy")]])
   end

	moveCursorEnd()
   if partyrelay then send("pt "..target..": epilepsy")
      end
end
ataxiaTemp.ignoreShield = nil