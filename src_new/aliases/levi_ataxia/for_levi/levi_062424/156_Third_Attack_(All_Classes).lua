--[[mudlet
type: alias
name: Third Attack (All Classes)
hierarchy:
- Levi_Ataxia
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^cc$
command: ''
packageName: ''
]]--

if gmcp.Char.Status.class == "Runewarden" and gmcp.Char.Vitals.charstats[3] == "Spec: Dual Blunt" then
  dwbRunie.dispatch()
end

if gmcp.Char.Status.class == "Depthswalker" then
  depthswalker.dispatch()
end

if gmcp.Char.Status.class == "Magi" then
  magi.offense.setMode("lock")
  magi.offense.dispatch()
end
