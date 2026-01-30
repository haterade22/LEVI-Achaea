if not tAffs.bleed or (tAffs.bleed and tAffs.bleed < 650) then tAffs.bleed = 650 end

tAffs.haemophilia = true

cecho(" <white>[<red>"..tAffs.bleed.."<white>]")

ataxiaTemp.coagulateAff = nil