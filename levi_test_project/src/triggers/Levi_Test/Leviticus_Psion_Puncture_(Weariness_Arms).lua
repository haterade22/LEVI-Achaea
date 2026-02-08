if tprepare == "disruption" then
send("pt " ..target..": Weariness and Paralysis")
elseif tprepare == "laceration" then
send("pt " ..target..": Weariness and Haemophilia")
elseif tprepare == "dazzle" then
send("pt " ..target..": Weariness and Clumsiness")
elseif tprepare == "rattle" then
send("pt " ..target..": Weariness and Epilepsy")
elseif tprepare == "vapours" then
send("pt " ..target..": Weariness and Asthma")
else
send("pt " ..target..": Weariness")
end
