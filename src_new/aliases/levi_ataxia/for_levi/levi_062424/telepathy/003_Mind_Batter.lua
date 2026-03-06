--[[mudlet
type: alias
name: Mind Batter
hierarchy:
- Levi_Ataxia
- Classes
- Monk
- Telepathy
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^mba$
command: ''
packageName: ''
]]--

send("queue addclear free mind batter " ..target)
