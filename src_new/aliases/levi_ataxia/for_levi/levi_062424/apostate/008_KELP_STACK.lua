--[[mudlet
type: alias
name: KELP STACK
hierarchy:
- Levi_Ataxia
- Classes
- Apostate
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
-- infernalpriosweariness() was deleted in 3c312975 with the old limb counters; guarded, because it threw.
if infernalpriosweariness then infernalpriosweariness() end
end

