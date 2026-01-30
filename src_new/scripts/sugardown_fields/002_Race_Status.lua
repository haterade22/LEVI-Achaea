--[[mudlet
type: script
name: Race Status
hierarchy:
- Sugardown Fields
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

function sugardown.startRace()
  sugardown.racing = true
  sugardown.betsByRacer = {}
  send("queue add eqbal racetrack bets")
  send("queue add eqbal racetrack view")
  tempTimer(155, [[sugardown.leftRace()]])
end

function sugardown.endRace()
  sugardown.racing = false
  sugardown.betsByRacer = {}
end

function sugardown.leftRace()
  if gmcp.Room.Info.name ~= "Sugardown Fields" then
    sugardown.endRace()
  end
end

function sugardown.racetrackView()
  if sugardown.racing then
    send("queue add eqbal racetrack view")
  end
end
