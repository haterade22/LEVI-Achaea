if not tAffs.bleed or (tAffs.bleed and tAffs.bleed < 550) then tAffs.bleed = 550 end

tAffs.haemophilia = true
if applyAffV3 then applyAffV3("haemophilia") end

cecho(" <white>[<red>"..tAffs.bleed.."<white>]")

ataxiaTemp.coagulateAff = nil