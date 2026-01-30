if not tAffs.bleed or (tAffs.bleed and tAffs.bleed <750) then tAffs.bleed = 750 end

tAffs.haemophilia = true

cecho(" <white>[<red>"..tAffs.bleed.."<white>]")

ataxiaTemp.coagulateAff = nil