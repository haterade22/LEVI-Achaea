if not ataxiaTemp.heartseedMode then
	ataxiaTemp.heartseedMode = true
	ataxiaEcho("Heartseed mode enabled.")
else
	ataxiaTemp.heartseedMode = nil
	ataxiaEcho("Heartseed mode disabled.") 
	
	ataxia_restorePrio("damagedleftleg")
	ataxia_restorePrio("damagedrightleg")
	ataxia_restorePrio("mangledleftleg")
	ataxia_restorePrio("mangledrightleg")
	ataxia_restorePrio("damagedleftarm")
	ataxia_restorePrio("damagedrightarm")
	ataxia_restorePrio("mangledleftarm")
	ataxia_restorePrio("mangledrightarm")
end