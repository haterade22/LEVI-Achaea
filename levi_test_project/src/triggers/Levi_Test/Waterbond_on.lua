if isTargeted(matches[2]) then
twaterbond = true
  if tAffs.frozen then
    tempTimer(45, [[twaterbond = false]])
  elseif tAffs.shiving then
    tempTimer(35, [[twaterbond = false]])
  elseif tAffs.nocaloric then
    tempTimer(25, [[twaterbond = false]])
  else
  tempTimer(15, [[twaterbond = false]])
  end
tarAffed("waterbond")
if applyAffV3 then applyAffV3("waterbond") end
if partyrelay and not ataxia.afflictions.aeon then send("pt " ..target.. ": Waterbond") end
end
  
  