local elements = {
  Sanya = "purple",
  Mir = "LightSkyBlue",
  Arash = "orange",
  Thyr = "NavajoWhite",
}
for stance, colour in pairs(elements) do
  if string.find(line, stance) and ataxia.vitals.stance == stance then
    selectString(line,1)
    fg(colour)
    deselect()
    resetFormat()
    ataxia_updateBlademasterStance()
  end
end