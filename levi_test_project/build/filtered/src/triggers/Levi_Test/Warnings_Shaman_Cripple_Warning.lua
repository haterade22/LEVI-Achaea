if not ataxiaTemp.usedTree then
	ataxia_boxEcho("Salvelock maybe incoming! Hold for tree")
	ataxiaTemp.salvelockWait = tempTimer(3.5, [[ killTimer(ataxiaTemp.salvelockWait); ataxiaTemp.salvelockWait = nil ]])
	
	local sp = ataxia.settings.separator or ";"
	send("curing predict manaleech"..sp.."focus")

end