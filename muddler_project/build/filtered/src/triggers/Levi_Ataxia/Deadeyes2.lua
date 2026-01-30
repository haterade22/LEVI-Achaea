tarInsomnia = tarInsomnia or true
deadaff = matches[2]

if isTargeted(matches[3])


and matches[2] ~= "clumsy" and matches[2] ~= "stupid" and matches[2] ~= "sicken" and matches[2] ~= "dizzy" and matches[2] ~= "vomiting" 
and matches[2] ~= "reckless" and matches[2] ~= "plague" and matches[2] ~= "bleed" and matches[2] ~= "breach" and matches[2] ~= "sleep" and matches[2] ~= "paralysis" then
	tarAffed(matches[2])
  
  cecho("working")
elseif matches[2] == "clumsy" then
tarAffed("clumsiness")
elseif matches[2] == "sensitivity" and not tAffs.deafness then
tarAffed("sensitivity")
elseif matches[2] == "sensitivity" and tAffs.deafness then
tAffs.deafness = false
elseif matches[2] == "stupid" then
tarAffed("stupidity")
elseif matches[2] == "dizzy" then
tarAffed("dizziness")
elseif matches[2] == "plague" then
tarAffed("voyria")
elseif matches[2] == "sicken"  then
tarAffed("manaleech")
elseif matches[2] == "vomiting"  then
tarAffed("nausea")
elseif matches[2] == "reckless"  then
tarAffed("recklessness")
elseif matches[2] == "confusion" then
tarAffed("confusion")
end
tAffs.curseward = false

if matches[2] == "sleep" and tAffs.hypersomnia and tarInsomnia == true then tarInsomnia = tempTimer(10, [[tarInsomnia = true; tarInsomnia = false]]) end


if partyrelay and not ataxia.afflictions.aeon and matches[2] ~= "sicken" then send("pt "..target..": "..matches[2]) elseif partyrelay and not ataxia.afflictions.aeon and matches[2] == "sicken" then send("pt "..target..": manaleech")
      end