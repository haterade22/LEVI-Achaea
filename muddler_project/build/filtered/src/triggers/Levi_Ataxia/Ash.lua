if matches[2] == target then
    if anorexiaFailsafe then
        tAffs[lastFocus] = true
        ataxiaEcho("Backtracked anorexia being cured with last focus.")
        anorexiaFailsafe = nil
        lastFocus = nil
    end
    if tAffs.crescendo and tAffs.crescendo ~= 0 then
      tAffs.crescendo = 0
      erAff("crescendo")
    end
    targetAteWrapper("ash")
if passiveFailsafe then restorePassiveCure() end
    tBals.plant = false
  if tBals.timers.plant then killTimer(tBals.timers.plant) end
    if tAffs.mercury then
        erAff("mercury")
        tBals.timers.plant = tempTimer(1.9, [[tBals.plant = true; tBals.timers.plant = nil]])
    else
        tBals.timers.plant = tempTimer(1.3, [[tBals.plant = true; tBals.timers.plant = nil]])
    end
    targetIshere = true
end
