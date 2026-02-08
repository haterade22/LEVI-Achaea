ataxia.afflictions.incoming_haemophilia = true
cecho("\n<a_green>     -= INCOMING HAEMOPHILIA =-")

tempTimer(5.1, [[ if affed("incoming_haemophilia") then ataxia.afflictions.incoming_haemophilia = nil end ]])