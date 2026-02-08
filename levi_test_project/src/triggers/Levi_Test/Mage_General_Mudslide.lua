tarAffed("slickness")
tarAffed("prone")
if applyAffV3 then applyAffV3("slickness"); applyAffV3("prone") end
if partyrelay and not ataxia.afflictions.aeon then send("pt " ..target.. ": Prone and Slickness") end
