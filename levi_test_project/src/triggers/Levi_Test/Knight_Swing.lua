local person = multimatches[1][4]
local maybemiss = multimatches[3][1]

if ataxiaTemp.class == "Bard" then return end

if isTargeted(person) then
  targetIshere = true
  tAffs.shield = false
  if removeAffV3 then removeAffV3("shield") end

	ataxiaTemp.ignoreShield = false
  lastLimbAttack = "dwcSlash"
  moveCursor(0, getLineNumber()-1)
  if ataxiaTemp.hitCount == 0 then
    if next(envenomList) then	
		  tarAffed(envenomList[1])
		  if applyAffV3 then applyAffV3(envenomList[1]) end
		  table.remove(envenomList, 1)
    end
  else  
    if envenomListTwo and next(envenomListTwo) then
      tarAffed(envenomListTwo[1])
      if applyAffV3 then applyAffV3(envenomListTwo[1]) end
      table.remove(envenomListTwo,1)
    else
      if next(envenomList) then	
  		  tarAffed(envenomList[1])
  		  if applyAffV3 then applyAffV3(envenomList[1]) end
  		  table.remove(envenomList, 1)
      end    
    end
	end
  moveCursorEnd()
end


ataxiaTemp.hitCount = ataxiaTemp.hitCount + 1