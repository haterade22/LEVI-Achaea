local person = multimatches[1][2]
local maybemiss = multimatches[3][1]



if isTargeted(person) then
  targetIshere = true
  tAffs.shield = false
  if removeAffV3 then removeAffV3("shield") end
  ignoreThirdPerson = true
  
  
  if partyrelay and not haveAff("weariness") then
  send("pt "..target..": weariness")
  elseif
partyrelay and  haveAff("weariness") then send("pt "..target..": lethargy weariness")

   end 

    moveCursor(0, getLineNumber()-1)
    
      if haveAff("weariness") then
        tarAffed("lethargy")
        if applyAffV3 then applyAffV3("lethargy") end
      else
        tarAffed("weariness")
        if applyAffV3 then applyAffV3("weariness") end
      end
       
    moveCursorEnd()
    lastLimbAttack = "shikKuro"

 

   
end


local damage = tonumber(multimatches[3][1])
   ataxiaTables.limbData.shikKuro = damage
