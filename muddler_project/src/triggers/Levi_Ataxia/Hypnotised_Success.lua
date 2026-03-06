tAffs.hypnotising = nil
tAffs.hypnotised = true
if applyAffV3 then applyAffV3("hypnotised") end
tAffs.hypnoseal = false
if removeAffV3 then removeAffV3("hypnoseal") end
ataxiaTemp.hypnoseal = false

selectString(line,1)
fg("DarkSlateBlue")
setBold(true)
resetFormat()
ataxia_boxEcho("HYPNOTIZED - BEGIN SUGGESTING!", "orange:white")