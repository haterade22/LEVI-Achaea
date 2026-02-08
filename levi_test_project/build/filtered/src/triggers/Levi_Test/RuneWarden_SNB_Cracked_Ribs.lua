tarAffed("paralysis")
tarAffed("sensitivity")
if applyAffV3 then applyAffV3("paralysis"); applyAffV3("sensitivity") end
if partyrelay and not ataxia.afflictions.aeon then
send("pt " ..target..": paralysis sensitivity")
end