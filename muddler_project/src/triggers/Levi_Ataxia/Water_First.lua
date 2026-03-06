if target == matches[2] then
  tarAffed("frostbite")
  if applyAffV3 then applyAffV3("frostbite") end
  if partyrelay and not ataxia.afflictions.aeon then send("pt " ..target.. ": Frostbite") end
end