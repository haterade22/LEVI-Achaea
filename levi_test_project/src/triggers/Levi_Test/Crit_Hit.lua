zData.db.addChar("crithits")
if matches[3] == "CRITICAL" then
  zData.db.addChar("crit1")
elseif matches[3] == "CRUSHING CRITICAL" then
  zData.db.addChar("crit2")
elseif matches[3] == "OBLITERATING CRITICAL" then
  zData.db.addChar("crit3")
elseif matches[3] == "ANNIHILATINGLY POWERFUL CRITICAL" then
  zData.db.addChar("crit4")
elseif matches[3] == "WORLD-SHATTERING CRITICAL" then
  zData.db.addChar("crit5")
elseif matches[3] == "PLANE-RAZING CRITICAL" then
  zData.db.addChar("crit6")
end