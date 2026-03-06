if tAffs.bleed == nil or tAffs.bleed == 0 then tAffs.bleed = 80 end

if tAffs.bleed > 100 and not ataxiaTemp.coagulateAff then
	tAffs.bleed = 80
	tAffs.haemophilia = false
	if removeAffV3 then removeAffV3("haemophilia") end
end
cecho(" <white>[<red>"..tAffs.bleed.."<white>]")

if not tAffs.haemophilia then
	tAffs.bleed = 0
end

ataxiaTemp.coagulateAff = nil