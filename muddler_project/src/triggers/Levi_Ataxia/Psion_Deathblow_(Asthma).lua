if partyrelay and not ataxia.afflictions.aeon then
if tprepare == "disruption" then
send("pt " ..target..": Asthma and Paralysis")
elseif tprepare == "laceration" then
send("pt " ..target..": Asthma and Haemophilia")
elseif tprepare == "dazzle" then
send("pt " ..target..": Asthma and Clumsiness")
elseif tprepare == "rattle" then
send("pt " ..target..": Asthma and Epilepsy")
elseif tprepare == "vapours" then
send("pt " ..target..": Asthma and Asthma")
else
send("pt " ..target..": Asthma")
end
end
