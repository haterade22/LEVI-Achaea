if not tAffs.bleed or (tAffs.bleed and tAffs.bleed < 850) then tAffs.bleed = 850 end

tarAffed("haemophilia")

cecho(" <white>[<red>"..tAffs.bleed.."<white>]")

ataxiaTemp.coagulateAff = nil

-- BM Brokenstar phase engine callback (800+ bleed = ready for brokenstar)
if blademaster and blademaster.onBleedingReady then blademaster.onBleedingReady() end
if blademaster and blademaster.onBleedingUpdate then blademaster.onBleedingUpdate(tAffs.bleed) end