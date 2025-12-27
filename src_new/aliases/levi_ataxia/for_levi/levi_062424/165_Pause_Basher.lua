--[[mudlet
type: alias
name: Pause Basher
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- Ataxia-DownloadThis
- Ataxia
- Autobashing
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^bash pause$
command: ''
packageName: ''
]]--

if ataxiaBasher.paused then
  ataxia_Echo("Unpausing to resume bashing.")
  ataxiaBasher.paused = false
  ataxiaBasher_patterns()
 else
  ataxia_Echo("Pausing all basher actions.")
  ataxiaBasher.paused = true
  send("cq all",false)
end