function keepAlive()
	sendGMCP("Core.KeepAlive")
	if keepAliveTimer then
		killTimer(keepAliveTimer)
	end

	keepAliveTimer = tempTimer(120, [[keepAlive()]])	
end

keepAlive()