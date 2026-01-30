if not tAffs.bleed or (tAffs.bleed and tAffs.bleed < 550) then tAffs.bleed = 550 end

tAffs.haemophilia = true

cecho(" <white>[<red>"..tAffs.bleed.."<white>]")

ataxiaTemp.coagulateAff = nil