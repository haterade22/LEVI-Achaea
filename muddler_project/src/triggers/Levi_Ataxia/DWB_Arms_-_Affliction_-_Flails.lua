if tAffs.paralysis then
  if ataxiaTemp.fractures.wristfractures == 0 or ataxiaTemp.fractures.wristfractures == nil then
    ataxiaTemp.fractures.wristfractures = 1
    twohanded_armsHit()
  else
    ataxiaTemp.fractures.wristfractures =  ataxiaTemp.fractures.wristfractures + 1
    twohanded_armsHit()
  end
   if partyrelay then send("pt "..target..": paralysis and " ..ataxiaTemp.fractures.wristfractures.. " wristfractures") end
   
else
  tarAffed("paralysis")
   if partyrelay then send("pt "..target..": paralysis") end
   
end

tempTimer(2.5, [[tarAffed("paralysis"]])