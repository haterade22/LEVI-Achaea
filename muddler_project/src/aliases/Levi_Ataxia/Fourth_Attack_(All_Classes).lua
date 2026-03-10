if gmcp.Char.Status.class == "Apostate" then
  apostate.setMode("group")
  apostate.dispatch()
end

if gmcp.Char.Status.class == "Serpent" then
  serp_setmode_darkshade()
  serp_ekanelia_offense()
end

if gmcp.Char.Status.class == "Blademaster" then
  bmbs()
end

if gmcp.Char.Status.class == "Runewarden" and gmcp.Char.Vitals.charstats[3] == "Spec: Dual Blunt" then
  dwbRunie.dispatch()
end

if gmcp.Char.Status.class == "Magi" then
  magi.offense.setMode("water")
  magi.offense.dispatch()
end
