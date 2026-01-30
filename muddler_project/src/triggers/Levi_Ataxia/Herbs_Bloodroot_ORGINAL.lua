if matches[2] == target then
tdeliverance = false
    if anorexiaFailsafe then
        tAffs[lastFocus] = true
        ataxiaEcho("Backtracked anorexia being cured with last focus.")
        anorexiaFailsafe = nil
        lastFocus = nil
    end
    
    if haveAff("prone") then
        if haveAff("slickness") and haveAff("paralysis") then
            tempTimer(0.5, [[
                if not haveAff("prone") then
                    ataxiaEcho("Backtracked paralysis being cured.")
                    erAff("paralysis")
                else
                    ataxiaEcho("Backtracked slickness being cured.")
                    erAff("slickness")
                end
            ]])
        else
            if tAffs.paralysis then
                erAff("paralysis")
            elseif tAffs.pyramides then
        erAff("pyramides")
      else
                erAff("slickness")
            end
        end
    else
            if tAffs.paralysis then
                erAff("paralysis")
            elseif tAffs.pyramides then
        erAff("pyramides")        
            else
                erAff("slickness")
            end
    end

    selectString(line, 1)
    fg("peru")
    resetFormat()

    tBals.plant = false
  if tBals.timers.plant then killTimer(tBals.timers.plant) end
    if tAffs.mercury then
        tAffs.mercury = false
        tBals.timers.plant = tempTimer(1.9, [[tBals.plant = true; tBals.timers.plant = nil]])
    else
        tBals.timers.plant = tempTimer(1.3, [[tBals.plant = true; tBals.timers.plant = nil]])
    end
    
    if strikingHigh and not strikeHighTimer then
        strikingHigh = nil
        strikeHighTimer = tempTimer(1.15, [[
            if ataxia.vitals.ferocity == 4 and not haveAff("rebounding") then
                send("shieldstrike "..target.." high")
            end     
            strikeHighTimer = nil
        ]])
    end    
    targetIshere = true
end
selectString(line, 1)
	fg("red")
	resetFormat()