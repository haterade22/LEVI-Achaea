if isTargeted(matches[2]) then
tdeliverance = false
erAff("brokenleftleg")
erAff("brokenrightleg")
erAff("brokenleftarm")
erAff("brokenrightarm")
-- Notify DWC vivisect systems of RESTORE
if infernalDWC then
    infernalDWC.enterRiftlock()
end
if infernalDWC2L then
    infernalDWC2L.enterRiftlock()
end
end
ataxia_boxEcho(" -------------------  USED RESTORE  -------------------", "blue")