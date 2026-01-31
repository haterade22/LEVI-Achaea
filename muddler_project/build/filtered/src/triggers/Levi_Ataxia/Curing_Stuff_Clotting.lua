if type(target) == "number" and ataxiaBasher.enabled then
	if not bashClotSub then 
		bashConsoleEcho("curing", "Clotted bleeding")	
		bashClotSub = tempTimer(1, [[ bashClotSub = nil ]])
	end
end

if ataxia.settings.gagclot then
	deleteFull()
end