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

if gmcp.Char.Status.class == "Runewarden" and ataxia.vitals.knight == "Dual Blunt" then
  dwbRunie.setMode("pulp")
  dwbRunie.dispatch()
end

if gmcp.Char.Status.class == "Depthswalker" then
  depthswalker.dispatch()
end

if gmcp.Char.Status.class == "Infernal" and ataxia.vitals.knight == "Dual Cutting" then
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

if gmcp.Char.Status.class == "Psion" then
  psion.setMode("flurry")
  psion.dispatch()
end
