ataxia.vitals.shaping = 4 
if ataxiaBasher.enabled and not ataxiaBasher.manual then
  deleteFull()
else
  local sColour = {[0] = "grey", [1] = "chat_bg", [2] = "DimGrey", [3] = "NavajoWhite", [4] = "chocolate",}
  selectString(line,1)
  fg(sColour[ataxia.vitals.shaping])
  deselect()
  resetFormat()
end