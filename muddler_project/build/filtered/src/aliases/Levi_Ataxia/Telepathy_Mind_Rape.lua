if affstrack.score.impatience<100 then
			send("cq all|queue add eqbal mind impatience " ..target)
	
	elseif affstrack.score.confusion<100 then
	send("cq all|queue add eqbal mind confuse " ..target)
		
	elseif affstrack.score.disrupt<100 then
	send("cq all|queue add eqbal mind disrupt " ..target)
	else 
	send("cq all|queue add eqbal mind batter " ..target)
	end