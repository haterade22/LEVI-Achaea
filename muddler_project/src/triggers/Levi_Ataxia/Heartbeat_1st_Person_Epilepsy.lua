ataxia.afflictions.incoming_epilepsy = true
cecho("\n<yellow>     -= INCOMING EPILEPSY =-")

tempTimer(5.1, [[ if affed("incoming_epilepsy") then ataxia.afflictions.incoming_epilepsy = nil end ]])