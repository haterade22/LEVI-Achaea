if target == matches[2] then
    tarAffed("conflagration")
    if applyAffV3 then applyAffV3("conflagration") end
    if partyrelay and not ataxia.afflictions.aeon then send("pt " ..target.. ": conflagration") end
    tburns = tburns or 2
  end

tfirelash = false