--[[mudlet
type: timer
name: NIGHTMARE TICK
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- leviticus
- APO
attributes:
  isActive: 'no'
  isFolder: 'no'
  isTempTimer: 'no'
  isOffsetTimer: 'no'
time: '00:00:06.500'
command: ''
packageName: ''
]]--



if gmcp.Char.Status.class == "Apostate" and demon() == "nightmare" then

maretick = true
tempTimer(2, [[maretick = false]])


else

maretick = false
disableTimer("NIGHTMARE TICK")

end

