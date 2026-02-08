erAff("paralysis")
if removeAffV3 then removeAffV3("paralysis") end
selectString(line,1)
fg("tomato")
resetFormat()
tAffs.curseward = true
if applyAffV3 then applyAffV3("curseward") end

local prevented_aff = curseConvert(matches[2])
erAff(prevented_aff)
if removeAffV3 then removeAffV3(prevented_aff) end

tAffs.bleed = tAffs.bleed - 40
if tAffs.bleed < 0 then tAffs.bleed = nil end