if tAffs.haemophilia then 
	tAffs.bleed = tAffs.bleed or 0
	tAffs.bleed = tAffs.bleed + 250 
end

ataxiaTemp.bloodlet = true
tarAffed("haemophilia")
if partyrelay then  send("pt "..target..": haemophilia") end

cecho(" <white>[<red>"..(tAffs.bleed or 0).."<white>]")