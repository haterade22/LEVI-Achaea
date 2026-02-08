if not tAffs.bleed or (tAffs.bleed and tAffs.bleed < 850) then tAffs.bleed = 850 end

tAffs.haemophilia = true
if applyAffV3 then applyAffV3("haemophilia") end

cecho(" <white>[<red>"..tAffs.bleed.."<white>]")

ataxiaTemp.coagulateAff = nil