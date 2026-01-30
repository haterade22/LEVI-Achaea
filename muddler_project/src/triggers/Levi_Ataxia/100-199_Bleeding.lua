if tAffs.bleed == nil or tAffs.bleed == 0 then tAffs.bleed = 120 end

if tAffs.bleed > 200 and not ataxiaTemp.coagulateAff then
	tAffs.bleed = 180
	tAffs.haemophilia = false
end
cecho(" <white>[<red>"..tAffs.bleed.."<white>]")

ataxiaTemp.coagulateAff = nil