--[[mudlet
type: alias
name: Perform Mockery (Unfollow)
hierarchy:
- Levi_Ataxia
- Artefacts
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^moc$
command: ''
packageName: ''
]]--

send("queue add eqbal perform mockery " ..target)