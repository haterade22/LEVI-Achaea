if target == matches[2] then
  tarAffed("healthleech")
  if applyAffV3 then applyAffV3("healthleech") end
  if partyrelay and not ataxia.afflictions.aeon then send("pt " ..target.. ": Healthleech") end
end