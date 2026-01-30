if ataxiaNDB_getClass(matches[2]) == "Serpent" then
  if ataxia.prioritySwaps.impSnap and ataxia.prioritySwaps.impSnap.active then
    if ataxia_getPrio("impatience") ~= 1 then
      ataxia_setAffPrio("impatience", 1)
      tempTimer(10, [[ ataxia_restorePrio("impatience") ]])
    end
  end
end