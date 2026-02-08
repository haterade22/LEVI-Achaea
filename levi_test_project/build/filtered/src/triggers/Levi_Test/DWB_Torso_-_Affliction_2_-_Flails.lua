if ataxiaTemp.fractures.crackedribs == 0 or ataxiaTemp.fractures.crackedribs == nil then
    ataxiaTemp.fractures.crackedribs = 1
    twohanded_torsoHit()
else
    ataxiaTemp.fractures.crackedribs = math.min(7, ataxiaTemp.fractures.crackedribs + 1)
    twohanded_torsoHit()
end
if partyrelay then send("pt "..target..": asthma and " ..ataxiaTemp.fractures.crackedribs.. " crackedribs") end

tarAffed("asthma")
if applyAffV3 then applyAffV3("asthma") end
tempTimer(2.5, [[tarAffed("asthma"); if applyAffV3 then applyAffV3("asthma") end]])
   
