local person = multimatches[2][2]:trim()

if selectString(person, 1) > 0 then fg("red") setBold(true) deselect() resetFormat() end
ataxia_setWarning("deliverance in room", 1)