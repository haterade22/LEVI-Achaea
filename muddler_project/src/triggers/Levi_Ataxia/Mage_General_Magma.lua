if target == matches[2] then
    tarAffed("scalded")
    if partyrelay and not ataxia.afflictions.aeon then send("pt " ..target.. ": Scalded") end
  end
tempTimer(20, [[erAff("scalded")]])
