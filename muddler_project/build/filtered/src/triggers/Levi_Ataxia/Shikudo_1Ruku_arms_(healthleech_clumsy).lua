local person = multimatches[1][2]
local maybemiss = multimatches[3][1]

if isTargeted(person) then
  targetIshere = true
  tAffs.shield = false
  if removeAffV3 then removeAffV3("shield") end
  ignoreThirdPerson = true
    if partyrelay and not haveAff("clumsiness") then
  send("pt "..target..": clumsiness")
   elseif
partyrelay and haveAff("clumsiness") then send("pt "..target..": healthleech clumsiness")
   end 

        if haveAff("clumsiness") then
        tarAffed("healthleech")
        if applyAffV3 then applyAffV3("healthleech") end
      else
        tarAffed("clumsiness")
        if applyAffV3 then applyAffV3("clumsiness") end
      end
    
    lastLimbAttack = "shikRuku"

     
end


local damage = tonumber(multimatches[3][1])
   ataxiaTables.limbData.shikRuku = damage
