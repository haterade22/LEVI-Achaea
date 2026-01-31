local person = multimatches[1][2]
local maybemiss = multimatches[3][1]



if isTargeted(person) then
  targetIshere = true
  tAffs.shield = false
  ignoreThirdPerson = true
  
  
  if partyrelay and not haveAff("weariness") then
  send("pt "..target..": weariness")
  elseif
partyrelay and  haveAff("weariness") then send("pt "..target..": lethargy weariness")

   end 

    moveCursor(0, getLineNumber()-1)
    
      if haveAff("weariness") then
        tarAffed("lethargy")
      else
        tarAffed("weariness")
      end
       
    moveCursorEnd()
    lastLimbAttack = "shikKuro"

 

   
end


local damage = tonumber(multimatches[3][1])
   ataxiaTables.limbData.shikKuro = damage
