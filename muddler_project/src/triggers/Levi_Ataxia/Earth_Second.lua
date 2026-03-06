if target == matches[2] then
  if not tAffs.paralysis then
    tarAffed("paralysis")
    if applyAffV3 then applyAffV3("paralysis") end
    if partyrelay and not ataxia.afflictions.aeon then send("pt " ..target.. ": Paralysis") end
  end
end