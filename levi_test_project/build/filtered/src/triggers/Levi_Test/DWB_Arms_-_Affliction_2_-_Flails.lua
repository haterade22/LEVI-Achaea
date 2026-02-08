if ataxiaTemp.fractures.wristfractures == 0 or ataxiaTemp.fractures.wristfractures == nil then
  ataxiaTemp.fractures.wristfractures = 1
  twohanded_armsHit()
else
  ataxiaTemp.fractures.wristfractures =  ataxiaTemp.fractures.wristfractures + 1
  twohanded_armsHit()
end
tarAffed("paralysis")
if applyAffV3 then applyAffV3("paralysis") end

if partyrelay then send("pt "..target..": paralysis and " ..ataxiaTemp.fractures.wristfractures.. " wristfractures") end

tempTimer(2.5, [[tarAffed("paralysis"); if applyAffV3 then applyAffV3("paralysis") end]])