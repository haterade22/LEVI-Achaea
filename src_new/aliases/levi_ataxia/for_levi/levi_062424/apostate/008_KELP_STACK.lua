--[[mudlet
type: alias
name: KELP STACK
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- LeviticusREG
- Leviticus
- APOSTATE
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^kel$
command: ''
packageName: ''
]]--

if gmcp.Char.Status.class == "Apostate" and ataxiaNDB_getClass(target) == "Occultist" or ataxiaNDB_getClass(target) == "Pariah" or ataxiaNDB_getClass(target) == "Priest" then
apostate_weari()

elseif gmcp.Char.Status.class == "Apostate" then
apostate_kelp()
end

if gmcp.Char.Status.class == "Runewarden" then
runiedwckelpstack2()
envenom2dwc()
end

if gmcp.Char.Status.class == "Infernal" then
infernalpriosweariness()
end

