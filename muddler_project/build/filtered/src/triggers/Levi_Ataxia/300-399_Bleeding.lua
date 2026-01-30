if not tAffs.bleed or (tAffs.bleed and tAffs.bleed < 370) then tAffs.bleed = 370 end

if tAffs.bleed > 400 and not ataxiaTemp.coagulateAff then
	tAffs.bleed = 380
	tAffs.haemophilia = false
end
cecho(" <white>[<red>"..tAffs.bleed.."<white>]")

ataxiaTemp.coagulateAff = nil