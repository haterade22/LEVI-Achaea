if matches[2] == target then
tdeliverance = false
    if anorexiaFailsafe then
        tAffs[lastFocus] = true
        ataxiaEcho("Backtracked anorexia being cured with last focus.")
        anorexiaFailsafe = nil
        lastFocus = nil
    end
    targetAteWrapper("mycalium")
     if onHerbCureV3 then onHerbCureV3("goldenseal") end
if passiveFailsafe then restorePassiveCure() end
    tBals.plant = false
  if tBals.timers.plant then killTimer(tBals.timers.plant) end
    if tAffs.mercury then
        tAffs.mercury = false
        tBals.timers.plant = tempTimer(1.9, [[tBals.plant = true; tBals.timers.plant = nil]])
    else
        tBals.timers.plant = tempTimer(1.3, [[tBals.plant = true; tBals.timers.plant = nil]])
    end
    targetIshere = true
end
  if passiveFailsafe then restorePassiveCure() end
	erAff("mycalium")

selectString(line, 1)
fg("PeachPuff")
resetFormat()