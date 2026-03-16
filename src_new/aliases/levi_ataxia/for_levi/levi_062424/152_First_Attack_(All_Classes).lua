--[[mudlet
type: alias
name: First Attack (All Classes)
hierarchy:
- Levi_Ataxia
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^zz$
command: ''
packageName: ''
]]--

if gmcp.Char.Status.class == "Monk" then
  if ataxia.vitals.stance then
    tekura6.config.kaiMode = "surge"
    tekura6.dispatch.run()
  else
    shikudo.dispatch()
  end
end

if gmcp.Char.Status.class == "Runewarden" and gmcp.Char.Vitals.charstats[3] == "Spec: Dual Blunt" then
  dwbRunie.setMode("torso")
  dwbRunie.dispatch()
end

if gmcp.Char.Status.class == "Infernal" and gmcp.Char.Vitals.charstats[4] == "Spec: Dual Cutting" then
  infernalDWCVivisect()
end

if gmcp.Char.Status.class == "Depthswalker" then
  depthswalker.dispatch()
end

if gmcp.Char.Status.class == "Blademaster" then
  bmd()
end

if gmcp.Char.Status.class == "Apostate" then
  apostate.setMode("lock")
  apostate.dispatch()
end

if gmcp.Char.Status.class == "Serpent" then
  serp_setmode_lock()
  serp_ekanelia_offense()
end

if gmcp.Char.Status.class == "Shaman" then
  shamanOffense.dispatch()
end

if gmcp.Char.Status.class == "Magi" then
  magi.offense.setMode("salve")
  magi.offense.dispatch()
end

if gmcp.Char.Status.class == "Psion" then
  psion.dispatch()
end
