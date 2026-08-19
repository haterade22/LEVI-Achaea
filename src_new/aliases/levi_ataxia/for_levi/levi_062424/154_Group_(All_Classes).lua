--[[mudlet
type: alias
name: Group (All Classes)
hierarchy:
- Levi_Ataxia
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^sr$
command: ''
packageName: ''
]]--

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
  -- v4.7.275: route through bmd() rather than setting the mode inline, so this entry point picks
  -- up markManual() (which drives blademaster.retryTick) and warnModeFlap(). `sr` is a manual
  -- press like any other, and it silently forcing mode="double" mid-fight is one of the ways the
  -- 2026-08-19 log ended up flapping double -> quad -> double and abandoning its prep.
  if bmd then
    bmd()
  elseif blademaster and blademaster.run then
    blademaster.state.mode = "double"
    blademaster.run()
  end
end

if gmcp.Char.Status.class == "Runewarden" and ataxia.vitals.knight == "Dual Blunt" then
  dwbRunie.setMode("group")
  dwbRunie.dispatch()
end

if gmcp.Char.Status.class == "Infernal" and ataxia.vitals.knight == "Dual Cutting" then
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
