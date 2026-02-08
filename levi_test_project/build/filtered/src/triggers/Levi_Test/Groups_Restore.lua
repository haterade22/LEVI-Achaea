if isTargeted(matches[2]) then
tdeliverance = false
erAff("brokenleftleg")
if removeAffV3 then removeAffV3("brokenleftleg") end
erAff("brokenrightleg")
if removeAffV3 then removeAffV3("brokenrightleg") end
erAff("brokenleftarm")
if removeAffV3 then removeAffV3("brokenleftarm") end
erAff("brokenrightarm")
if removeAffV3 then removeAffV3("brokenrightarm") end
-- Notify DWC vivisect systems of RESTORE
if infernalDWC then
    infernalDWC.enterRiftlock()
end
if infernalDWC2L then
    infernalDWC2L.enterRiftlock()
end
end
ataxia_boxEcho(" -------------------  USED RESTORE  -------------------", "blue")