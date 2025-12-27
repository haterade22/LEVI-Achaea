--[[mudlet
type: script
name: keepAlive
hierarchy:
- Levi_Ataxia
- LEVI
- Ataxia
- Ataxia
- Misc Scripts
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

function keepAlive()
	sendGMCP("Core.KeepAlive")
	if keepAliveTimer then
		killTimer(keepAliveTimer)
	end

	keepAliveTimer = tempTimer(120, [[keepAlive()]])	
end

keepAlive()