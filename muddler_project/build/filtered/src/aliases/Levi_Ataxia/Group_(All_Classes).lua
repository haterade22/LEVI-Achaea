if gmcp.Char.Status.class == "Apostate" then
  apostate.setMode("group")
  apostate.dispatch()
end

if gmcp.Char.Status.class == "Monk" then
  shikudolock()
end

if gmcp.Char.Status.class == "Serpent" then
  serp_setmode_group()
  serp_ekanelia_offense()
end

if gmcp.Char.Status.class == "Blademaster" then
  if blademaster and blademaster.run then
    blademaster.state.mode = "double"
    blademaster.run()
  end
end

if gmcp.Char.Status.class == "Runewarden" and gmcp.Char.Vitals.charstats[3] == "Spec: Dual Blunt" then
  dwbRunie.setMode("group")
  dwbRunie.dispatch()
end

if gmcp.Char.Status.class == "Infernal" and gmcp.Char.Vitals.charstats[4] == "Spec: Dual Cutting" then
  infernalGroupLockAttack()
end

if gmcp.Char.Status.class == "Shaman" then
  shamanOffense.setMode("group")
  shamanOffense.dispatch()
end

if gmcp.Char.Status.class == "Magi" then
  magi.offense.setMode("group")
  magi.offense.dispatch()
end
