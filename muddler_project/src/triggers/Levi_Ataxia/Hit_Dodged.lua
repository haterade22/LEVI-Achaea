-- Check if this is rebounding specifically
local isRebounding = (line == "The attack rebounds back onto you!")

-- If rebounding, we need to undo the affliction that was just tracked
-- because the attack didn't actually land
if isRebounding and ataxiaTemp.lastAffAdded then
    erAff(ataxiaTemp.lastAffAdded)
    -- V2 support: also remove from V2 tracking
    if removeAffV2 then removeAffV2(ataxiaTemp.lastAffAdded) end
    ataxiaEcho("[REBOUND] Attack rebounded - removed " .. ataxiaTemp.lastAffAdded .. " from tracking")
    -- If it was exploit (weariness+paranoia), also remove paranoia
    if ataxiaTemp.lastAffAddedExtra then
        erAff(ataxiaTemp.lastAffAddedExtra)
        if removeAffV2 then removeAffV2(ataxiaTemp.lastAffAddedExtra) end
    end
    ataxiaTemp.lastAffAdded = nil
    ataxiaTemp.lastAffAddedExtra = nil
    -- DON'T increment hitCount on rebound - the attack didn't land
    -- Also decrement hitCount since the swing trigger already incremented it
    ataxiaTemp.hitCount = ataxiaTemp.hitCount - 1
    return
end

ataxiaTemp.hitCount = ataxiaTemp.hitCount + 1
