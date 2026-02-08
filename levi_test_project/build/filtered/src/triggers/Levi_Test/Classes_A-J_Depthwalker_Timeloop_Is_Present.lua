checkTimeloop = true
if isTargeted(matches[2]) then
	tAffs.timeloop = true
	if applyAffV3 then applyAffV3("timeloop") end
	if Target_Instill == "depression" then
		if not haveAff("depression") then
			tarAffed("depression")
			if applyAffV3 then applyAffV3("depression") end
		elseif not haveAff("nausea") then
			tarAffed("nausea")
			if applyAffV3 then applyAffV3("nausea") end
		elseif not haveAff("hypochondria") then
			tarAffed("hypochondria")
			if applyAffV3 then applyAffV3("hypochondria") end
		else
			tarAffed("depression", "anorexia", "masochism")
			if applyAffV3 then applyAffV3("depression"); applyAffV3("anorexia"); applyAffV3("masochism") end
		end
	elseif Target_Instill == "degeneration" then
		if not haveAff("clumsiness") then
			tarAffed("clumsiness")
			if applyAffV3 then applyAffV3("clumsiness") end
		elseif not haveAff("weariness") then
			tarAffed("weariness")
			if applyAffV3 then applyAffV3("weariness") end
		else
			tarAffed("weariness", "clumsiness", "paralysis")
			if applyAffV3 then applyAffV3("weariness"); applyAffV3("clumsiness"); applyAffV3("paralysis") end
		end
	elseif Target_Instill == "retribution" then
		if not haveAff("justice") then
			tarAffed("justice")
			if applyAffV3 then applyAffV3("justice") end
		else
			tarAffed("retribution")
			if applyAffV3 then applyAffV3("retribution") end
		end
	elseif Target_Instill == "leach" then
		if not haveAff("parasite") then
			tarAffed("parasite")
			if applyAffV3 then applyAffV3("parasite") end
		elseif not haveAff("healthleech") then
			tarAffed("healthleech")
			if applyAffV3 then applyAffV3("healthleech") end
		else
			tarAffed("parasite", "healthleech", "manaleech")
			if applyAffV3 then applyAffV3("parasite"); applyAffV3("healthleech"); applyAffV3("manaleech") end
		end
	else
		if not haveAff("shadowmadness") then
			tarAffed("shadowmadness")
			if applyAffV3 then applyAffV3("shadowmadness") end
		elseif not haveAff("vertigo") then
			tarAffed("vertigo")
			if applyAffV3 then applyAffV3("vertigo") end
		else
			tarAffed("hallucinations")
			if applyAffV3 then applyAffV3("hallucinations") end
		end
	end
end