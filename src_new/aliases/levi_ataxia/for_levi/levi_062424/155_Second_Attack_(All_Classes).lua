--[[mudlet
type: alias
name: Second Attack (All Classes)
hierarchy:
- Levi_Ataxia
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^xx$
command: ''
packageName: ''
]]--

if gmcp.Char.Status.class == "Monk" then
  if ataxia.vitals.stance then
    tekura.dispatch.run()
  else
    shikudo.dispatch()
  end
end

if gmcp.Char.Status.class == "Blademaster" then
  bmdq()
end

if gmcp.Char.Status.class == "Runewarden" and gmcp.Char.Vitals.charstats[3] == "Spec: Dual Blunt" then
  dwbRunie.setMode("pulp")
  dwbRunie.dispatch()
end

if gmcp.Char.Status.class == "Depthswalker" then
  depthswalker.dispatch()
end

if gmcp.Char.Status.class == "Infernal" and gmcp.Char.Vitals.charstats[4] == "Spec: Dual Cutting" then
  infernalDWC2LVivisect()
end

if gmcp.Char.Status.class == "Apostate" then
  apostate.setMode("mental")
  apostate.dispatch()
end

if gmcp.Char.Status.class == "Serpent" then
  serp_setmode_hypnolock()
end

if gmcp.Char.Status.class == "Magi" then
  magi.offense.setMode("fire")
  magi.offense.dispatch()
end
