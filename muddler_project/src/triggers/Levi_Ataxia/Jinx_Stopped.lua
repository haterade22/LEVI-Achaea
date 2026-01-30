erAff("paralysis")
selectString(line,1)
fg("tomato")
resetFormat()
tAffs.curseward = true

local prevented_aff = curseConvert(matches[2])
erAff(prevented_aff)

tAffs.bleed = tAffs.bleed - 40
if tAffs.bleed < 0 then tAffs.bleed = nil end