ataxiaTemp.coagulate = true
tarAffed(ataxiaTemp.coagulateAff)
if applyAffV3 then applyAffV3(ataxiaTemp.coagulateAff) end
if partyrelay and not ataxia.afflictions.aeon then send("pt "..target..": "..ataxiaTemp.coagulateAff) end
tAffs.bleed = tAffs.bleed - 140
if tAffs.bleed < 0 then tAffs.bleed = nil end