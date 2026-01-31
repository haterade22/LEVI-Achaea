checkTimeloop = true
if isTargeted(matches[2]) then
	tAffs.timeloop = true
	if Target_Instill == "depression" then
		if not haveAff("depression") then
			tarAffed("depression")
		elseif not haveAff("nausea") then
			tarAffed("nausea")
		elseif not haveAff("hypochondria") then
			tarAffed("hypochondria")
		else
			tarAffed("depression", "anorexia", "masochism")
		end
	elseif Target_Instill == "degeneration" then
		if not haveAff("clumsiness") then
			tarAffed("clumsiness")
		elseif not haveAff("weariness") then
			tarAffed("weariness")
		else
			tarAffed("weariness", "clumsiness", "paralysis")
		end
	elseif Target_Instill == "retribution" then
		if not haveAff("justice") then
			tarAffed("justice")
		else
			tarAffed("retribution")
		end
	elseif Target_Instill == "leach" then
		if not haveAff("parasite") then
			tarAffed("parasite")
		elseif not haveAff("healthleech") then
			tarAffed("healthleech")
		else
			tarAffed("parasite", "healthleech", "manaleech")
		end
	else
		if not haveAff("shadowmadness") then
			tarAffed("shadowmadness")
		elseif not haveAff("vertigo") then
			tarAffed("vertigo")
		else
			tarAffed("hallucinations")
		end
	end
end