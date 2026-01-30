ataxia_boxEcho("WE HAVE STARTED TO TUMBLE "..matches[2].."!", "orange")
--clearCmdLine()
--appendCmdLine(matches[2])	

autotumbler = false
if ataxiaTemp.fakeLeave and gmcp.Char.Status.class == "Bard" then
  send("queue add class sing prelude "..gmcp.Char.Status.name.." tumbles out to the "..ataxiaTemp.fakeLeave..".")
  ataxiaTemp.fakeLeave = nil
end

if ataxia.prioritySwaps and ataxia.prioritySwaps.parshield and ataxia.prioritySwaps.parshield.active then
  sendAll("curing priority slickness 25;curing priority paralysis 25",false)
  tempTimer(3.5, [[ ataxia_restorePrio("paralysis");ataxia_restorePrio("slickness") ]])
end