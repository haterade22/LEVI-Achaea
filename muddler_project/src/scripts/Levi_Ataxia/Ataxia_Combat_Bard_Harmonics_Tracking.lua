function ataxia_nextHarmonic()

	
	if not next(ataxiaTemp.harms) then
		ataxiaTemp.summoningHarms = nil
		ataxiaTemp.harmsSummoned = true
		ataxiaTemp.needSymphony = true
		ataxiaEcho("Harmonics summoning completed. Refreshing to max duration.")
		comm = comm.." ;play symphony"
	else
		ataxiaEcho("Calling "..ataxiaTemp.harms[1].." next.")
		comm = "wield rapier;wield lyre;play "..ataxiaTemp.harms[1]
	end
	
	send("queue addclear free " ..comm)
end