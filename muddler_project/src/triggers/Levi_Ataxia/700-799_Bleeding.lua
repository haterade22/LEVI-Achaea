if not tAffs.bleed or (tAffs.bleed and tAffs.bleed <750) then tAffs.bleed = 750 end

tAffs.haemophilia = true
if applyAffV3 then applyAffV3("haemophilia") end

cecho(" <white>[<red>"..tAffs.bleed.."<white>]")

ataxiaTemp.coagulateAff = nil

-- BM Brokenstar phase engine callback (700+ bleed = ready for brokenstar)
if blademaster and blademaster.onBleedingReady then blademaster.onBleedingReady() end
if blademaster and blademaster.onBleedingUpdate then blademaster.onBleedingUpdate(tAffs.bleed) end