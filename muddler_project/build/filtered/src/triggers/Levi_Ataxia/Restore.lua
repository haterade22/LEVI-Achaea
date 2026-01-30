if isTargeted(matches[2]) then
tdeliverance = false
erAff("brokenleftleg")
erAff("brokenrightleg")
erAff("brokenleftarm")
erAff("brokenrightarm")
-- Reset limb counter for all limbs
if lb and lb[target] and lb[target].hits then
    lb[target].hits["left arm"] = 0
    lb[target].hits["right arm"] = 0
    lb[target].hits["left leg"] = 0
    lb[target].hits["right leg"] = 0
end
-- Notify DWC vivisect systems of RESTORE
if infernalDWC then
    infernalDWC.enterRiftlock()
end
if infernalDWC2L then
    infernalDWC2L.enterRiftlock()
end
end
ataxia_boxEcho(" -------------------  USED RESTORE  -------------------", "blue")