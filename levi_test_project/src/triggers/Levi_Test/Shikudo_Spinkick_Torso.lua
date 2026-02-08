local person = multimatches[1][2]
local maybemiss = multimatches[3][1]

if isTargeted(person) then
  targetIshere = true
  tAffs.shield = false
  if removeAffV3 then removeAffV3("shield") end
  ignoreThirdPerson = true

    lastLimbAttack = "shikSpinkickTorso"
if  ataxiaTemp.shikCombo.attackone == "kuro" and ataxiaTemp.shikCombo.attacktwo == "kuro" then
relaydoublekuro = true else relaydoublekuro = false  end
if  ataxiaTemp.shikCombo.attackone == "ruku" and ataxiaTemp.shikCombo.attacktwo == "ruku" then
relaydoubleruku = true else relaydoubleruku = false  end


if partyrelay and relaydoublekuro then  send("pt "..target..": weariness lethargy")
elseif partyrelay and relaydoubleruku then  send("pt "..target..": clumsiness healthleech")


end
end

local damage = tonumber(multimatches[3][1])
   ataxiaTables.limbData.shikSpinkickTorso = damage
