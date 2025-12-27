--[[mudlet
type: alias
name: Shikudo Artifact Level
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- Ataxia-DownloadThis
- Ataxia
- Combat Aliases
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^aconfig shikstaff (1|1.1|1.15|1.2|1.3)$
command: ''
packageName: ''
]]--

ataxiaEcho("Shikudo artifact level has been set to: <green>"..matches[2]..".")
ataxia.shikudoLevel = tonumber(matches[2])
ataxia_saveSettings(false)