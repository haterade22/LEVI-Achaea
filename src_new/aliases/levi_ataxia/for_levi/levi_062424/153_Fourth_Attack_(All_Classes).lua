--[[mudlet
type: alias
name: Fourth Attack (All Classes)
hierarchy:
- Levi_Ataxia
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^vv$
command: ''
packageName: ''
]]--

if gmcp.Char.Status.class == "Apostate" then
  apostate.setMode("group")
  apostate.dispatch()
end

if gmcp.Char.Status.class == "Serpent" then
  serp_setmode_darkshade()
  serp_ekanelia_offense()
end

if gmcp.Char.Status.class == "Monk" then
  if ataxia.vitals.stance then
    tekura6.config.kaiMode = "cripple"
    tekura6.dispatch.run()
  else
    -- v4.7.419: this called shikudo.setMode("godmode"), which only the switched-off 008 defines, so
    -- every press on a Shikudo threw -- and 006's dispatch has no mode routing, so GodMode (009, now
    -- retired) was never reachable anyway. vv runs the Telepathy variant of the dispatch offense once
    -- shikudo.dispatchMind exists (011), and until then the plain dispatch offense, as zz does.
    if shikudo.dispatchMind then shikudo.dispatchMind() else shikudo.dispatch() end
  end
end

if gmcp.Char.Status.class == "Blademaster" then
  bmbs()
end

if gmcp.Char.Status.class == "Runewarden" and ataxia.vitals.knight == "Dual Blunt" then
  dwbRunie.dispatch()
end

if gmcp.Char.Status.class == "Magi" then
  magi.offense.setMode("water")
  magi.offense.dispatch()
end

if gmcp.Char.Status.class == "Psion" then
  psion.setMode("mind")
  psion.dispatch()
end
