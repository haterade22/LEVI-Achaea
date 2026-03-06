if target == matches[2] then
  if tAffs.deaf == false then
  tarAffed("sensitivity")
  if applyAffV3 then applyAffV3("sensitivity") end
    if partyrelay and not ataxia.afflictions.aeon then send("pt " ..target.. ": sensitivity") end
  else
    tAffs.deaf = false
    if removeAffV3 then removeAffV3("deaf") end
  end
 
end