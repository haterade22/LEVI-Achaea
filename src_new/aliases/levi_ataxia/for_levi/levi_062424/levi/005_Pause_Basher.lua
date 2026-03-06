--[[mudlet
type: alias
name: Pause Basher
hierarchy:
- Levi_Ataxia
- Ataxia
- Basher
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