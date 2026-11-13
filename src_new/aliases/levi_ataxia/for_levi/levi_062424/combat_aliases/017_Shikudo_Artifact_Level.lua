--[[mudlet
type: alias
name: Shikudo Artifact Level
hierarchy:
- Levi_Ataxia
- Combat
- Combat Aliases
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^aconfig shikstaff (1|1.1|1.15|1.2|1.3)$
command: ''
packageName: ''
]]--

-- The damage multiplier of an artefact Shikudo staff (1 = a plain staff). Read by shikudo/006
-- getAttackDamage, which scales its default strike damage (other monks' figures) by it (v4.7.494;
-- before that only the switched-off 008 read it).
ataxiaEcho("Shikudo artifact level has been set to: <green>"..matches[2]..".")
ataxia.shikudoLevel = tonumber(matches[2])
ataxia_saveSettings(false)