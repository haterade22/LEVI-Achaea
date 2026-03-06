local person = multimatches[1][3]

if isTargeted(person) then
  targetIshere = true
  tAffs.shield = false
  if removeAffV3 then removeAffV3("shield") end

	ataxiaTemp.ignoreShield = false
	
    lastLimbAttack = "snbSlice"
      if partyrelay then send("pt "..target..": "..affstruck)
      end
	
end

