local name = matches[2]
local class = (ataxiaNDB_getClass(name) or "Unknown")

if isTargeted(name) and class == "Sylvan" then
  -- Sylvan root cures haemophilia + 1 random
  erAff("haemophilia")
  ataxiaTemp.randomCure = 1
  if removeAffV2 then removeAffV2("haemophilia") end
  if reduceRandomAffCertaintyV2 then reduceRandomAffCertaintyV2() end
  if onPassiveCureV3 then onPassiveCureV3(1) end
  selectString(line,1)
  fg("NavajoWhite")
  resetFormat()
  targetIshere = true
end
