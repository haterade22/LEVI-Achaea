if pariah.expose then
  pariah.expose = false
end

if pariah.virulence then killTimer(pariah.virulence) end
pariah.virulence = tempTimer(10, [[ pariah.virulence = nil ]])

selectString(line,1)
fg("DarkOrchid")
deselect()
resetFormat()