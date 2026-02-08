setTriggerStayOpen("Reagent Butchering", 0)
if ataxiaTemp.toButcher[1] and ataxiaTemp.butchering then
	sendAll("wield cleaver", "queue addclear free butcher "..ataxiaTemp.toButcher[1].." for reagent",false)
elseif ataxiaTemp.butchering then
	ataxiaTemp.butchering = nil
end