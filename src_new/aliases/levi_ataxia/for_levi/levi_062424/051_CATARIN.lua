--[[mudlet
type: alias
name: CATARIN
hierarchy:
- Levi_Ataxia
- Classes
- Dragon
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^cat$
command: ''
packageName: ''
]]--

-- Was expandALias (capital L), which nothing defines: the alias threw before the draw.
expandAlias("bp")
send("clearqueue all;legenddeck draw catarin")