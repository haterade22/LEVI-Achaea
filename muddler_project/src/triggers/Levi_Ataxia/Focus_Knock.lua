ataxiaTemp.hombal = true

tBals.focus = false
if haveAff("shadowmadness") then
  tempTimer(5, [[tBals.focus = true]])
else
  tempTimer(2.3, [[tBals.focus = true]])
end
targetIshere = true

selectString(line, 1)
fg("goldenrod")
deselect()
resetFormat()