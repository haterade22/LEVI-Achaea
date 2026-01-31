--[[mudlet
type: script
name: Guardians Of MoG
hierarchy:
- Levi_Ataxia
- LEVI
- Ataxia
- Basher
- Bashing
attributes:
  isActive: 'no'
  isFolder: 'no'
packageName: ''
]]--

function findcuntyguardians()
if gmcp.Room.Info.area == "Moghedu" then
  if ataxia.playersHere == "Hikagejuunin" then
  guardianofmogcunts = true
  ataxiaBasher.pause = true
  ataxiaBasher_areaoff()
  expandAlias("mstop")
  send("cq all")
  expandAlias("goto Mhaldor")
  end
    
end
end

