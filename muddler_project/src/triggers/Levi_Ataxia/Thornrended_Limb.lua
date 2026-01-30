local person = multimatches[1][3]
local propAff = sylvan_propagateAff()

if isTargeted(person) then
  targetIshere = true
  tAffs.shield = false
  moveCursor(0, getLineNumber()-1)
	if next(envenomList) then	
		tarAffed(envenomList[1], propAff)
		table.remove(envenomList, 1)
  else
    tarAffed(propAff)
	end
	moveCursorEnd()
  lastLimbAttack = "thornrend"  
end

