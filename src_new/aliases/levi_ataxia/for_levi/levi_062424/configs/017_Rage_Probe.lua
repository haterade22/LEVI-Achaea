--[[mudlet
type: alias
name: Rage Probe
hierarchy:
- Levi_Ataxia
- Ataxia
- Basher
- Configs
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^bash probe(?:\s+(\w+))?(?:\s+(.+))?$
command: ''
packageName: ''
]]--

-- `bash probe on|off|at <n>|report [filter]|bands [filter]|dump [n]|clear|status`
-- Measures a rage-threshold damage bonus from live play -- see basher/009_Rage_Probe.
if ataxiaBasher_rageProbeCommand then
	ataxiaBasher_rageProbeCommand(matches[2], matches[3])
else
	ataxiaEcho("Rage probe not loaded (basher/009_Rage_Probe).")
end
