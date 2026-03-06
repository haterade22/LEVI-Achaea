local person = multimatches[1][3]
local maybemiss = multimatches[3][1]
ataxiaTemp.lastLimbHit = multimatches[1][4]

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
      cecho("this is "..affstruck)
			table.remove(envenomList, 1)
			moveCursorEnd()
       lastLimbAttack = "bardRapier"

	end
end

local damage = tonumber(multimatches[3][3])
   ataxiaTables.limbData.bardRapier = damage
