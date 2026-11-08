--[[mudlet
type: alias
name: BECKON
hierarchy:
- Levi_Ataxia
- Classes
- Apostate
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^bec$
command: ''
packageName: ''
]]--

-- Was `..tar`, a global nothing sets: the concatenation threw and nothing was sent.
send("cq all;demon beckon " ..target)