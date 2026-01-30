if not tAffs.bleed or (tAffs.bleed and tAffs.bleed < 450) then tAffs.bleed = 450 end

if tAffs.bleed > 500 and not ataxiaTemp.coagulateAff then
	tAffs.bleed = 480
	tAffs.haemophilia = false
end
cecho(" <white>[<red>"..tAffs.bleed.."<white>]")

tAffs.haemophilia = true
ataxiaTemp.coagulateAff = nil