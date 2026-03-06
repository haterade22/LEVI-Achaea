if tAffs.haemophilia then 
	tAffs.bleed = tAffs.bleed or 0
	tAffs.bleed = tAffs.bleed + 250 
end

ataxiaTemp.bloodlet = true
tarAffed("haemophilia")
if applyAffV3 then applyAffV3("haemophilia") end
if partyrelay then  send("pt "..target..": haemophilia") end

cecho(" <white>[<red>"..(tAffs.bleed or 0).."<white>]")