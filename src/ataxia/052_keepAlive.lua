-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Ataxia-DownloadThis > Ataxia > Misc Scripts > keepAlive

function keepAlive()
	sendGMCP("Core.KeepAlive")
	if keepAliveTimer then
		killTimer(keepAliveTimer)
	end

	keepAliveTimer = tempTimer(120, [[keepAlive()]])	
end

keepAlive()