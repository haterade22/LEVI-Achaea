tAffs.rebounding = false
tAffs.shield = false
tshield = false
trebounding = false
tAffs.curseward = false

-- Illusion detected; undo any shield set on the next 2 lines
tempLineTrigger(1, 1, [[tAffs.shield = false; if tAffsV2 then tAffsV2.shield = 0 end]])
tempLineTrigger(2, 1, [[tAffs.shield = false; if tAffsV2 then tAffsV2.shield = 0 end]])