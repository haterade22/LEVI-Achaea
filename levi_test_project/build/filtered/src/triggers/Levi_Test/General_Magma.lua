if target == matches[2] then
    tarAffed("scalded")
    if applyAffV3 then applyAffV3("scalded") end
    if partyrelay and not ataxia.afflictions.aeon then send("pt " ..target.. ": Scalded") end
  end
tempTimer(20, [[erAff("scalded"); if removeAffV3 then removeAffV3("scalded") end]])
