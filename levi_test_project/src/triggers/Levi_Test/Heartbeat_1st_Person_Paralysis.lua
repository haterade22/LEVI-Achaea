ataxia.afflictions.incoming_paralysis = true
cecho("\n<red>     -= INCOMING PARALYSIS =-")

tempTimer(5.1, [[ if affed("incoming_paralysis") then ataxia.afflictions.incoming_paralysis = nil end ]])