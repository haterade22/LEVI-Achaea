local propAff = sylvan_propagateAff()

local person = multimatches[1][3]
local propAff = sylvan_propagateAff()

if isTargeted(person) then
  targetIshere = true
  tAffs.shield = false
  if removeAffV3 then removeAffV3("shield") end
  moveCursor(0, getLineNumber()-1)
	if next(envenomList) then	
		tarAffed(envenomList[1], propAff)
		if applyAffV3 then applyAffV3(envenomList[1], propAff) end
		table.remove(envenomList, 1)
  else
    tarAffed(propAff)
    if applyAffV3 then applyAffV3(propAff) end
	end
	moveCursorEnd()
end

