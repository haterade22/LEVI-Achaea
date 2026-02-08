if not tAffs.bleed or (tAffs.bleed and tAffs.bleed < 280) then tAffs.bleed = 280 end

if tAffs.bleed > 300 and not ataxiaTemp.coagulateAff then
	tAffs.bleed = 280
	tAffs.haemophilia = false
	if removeAffV3 then removeAffV3("haemophilia") end
end
cecho(" <white>[<red>"..tAffs.bleed.."<white>]")

ataxiaTemp.coagulateAff = nil