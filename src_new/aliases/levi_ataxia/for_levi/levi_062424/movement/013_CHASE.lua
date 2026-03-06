--[[mudlet
type: alias
name: CHASE
hierarchy:
- Levi_Ataxia
- General
- Movement
attributes:
  isActive: 'no'
  isFolder: 'no'
regex: ^ch$
command: ''
packageName: ''
]]--

killcurses()
send("who east;;who northeast;;who north;;who south;;who west;;who northwest;;who southwest;;who southeast;;who up;;who down;;who in;;who out")
