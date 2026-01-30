-- Notify DWC vivisect systems of parry detection
-- Each system reads its own state.lastTargetedLimb to know which limb was parried
if isTargeted(matches[2]) then
    if infernalDWC and infernalDWC.onParry then
        infernalDWC.onParry()
    end
    if infernalDWC2L and infernalDWC2L.onParry then
        infernalDWC2L.onParry()
    end
end
