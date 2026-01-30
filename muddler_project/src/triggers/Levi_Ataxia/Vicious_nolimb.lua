local person = matches[3]



if isTargeted(person) then

  targetIshere = true
  tAffs.shield = false

	ataxiaTemp.ignoreShield = false
	if next(envenomList) then
			moveCursor(0, getLineNumber()-1)
			tarAffed(envenomList[1])
     local affstruck = envenomList[1]
       if partyrelay then send("pt "..target..": "..affstruck)
      end
      cecho("this is "..affstruck)
			table.remove(envenomList, 1)
			moveCursorEnd()
       lastLimbAttack = "bardRapier"

	end
   if multimatches[3][1] == "The songblessing upon the rapier swells with a rich, vibrant hum." then
		    tarAffed("prone")
    end
end

