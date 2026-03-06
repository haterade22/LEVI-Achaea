tAffs.rebounding = false
if removeAffV3 then removeAffV3("rebounding") end
tAffs.shield = false
if removeAffV3 then removeAffV3("shield") end
tshield = false
trebounding = false
tAffs.curseward = false
if removeAffV3 then removeAffV3("curseward") end

-- Illusion detected; undo any shield set on the next 2 lines
tempLineTrigger(1, 1, [[tAffs.shield = false; if tAffsV2 then tAffsV2.shield = 0 end]])
if removeAffV3 then removeAffV3("shield") end
tempLineTrigger(2, 1, [[tAffs.shield = false; if tAffsV2 then tAffsV2.shield = 0 end]])
if removeAffV3 then removeAffV3("shield") end