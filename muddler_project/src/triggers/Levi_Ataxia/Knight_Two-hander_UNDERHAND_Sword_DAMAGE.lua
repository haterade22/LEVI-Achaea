local person = multimatches[1][2]
local maybemiss = multimatches[3][1]
ataxiaTemp.lastLimbHit = "torso"
if isTargeted(person) then

  targetIshere = true
  tAffs.shield = false
  if removeAffV3 then removeAffV3("shield") end

	ataxiaTemp.ignoreShield = false
	if next(envenomList) then
			moveCursor(0, getLineNumber()-1)
			tarAffed(envenomList[1])
			if applyAffV3 then applyAffV3(envenomList[1]) end
     local affstruck = envenomList[1]
       if partyrelay then send("pt "..target..": "..affstruck)
      end
			table.remove(envenomList, 1)
			moveCursorEnd()

	end
end
       lastLimbAttack = "twoHander"

local damage = tonumber(multimatches[3][3])
   ataxiaTables.limbData.twoHander = damage
