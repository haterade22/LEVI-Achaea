--[[mudlet
type: alias
name: NO MORE HUNTING
hierarchy:
- Levi_Ataxia
- Artefacts
- Rageblade
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^norage$
command: ''
packageName: ''
]]--

send("wield shield")
send("curing siphealth 80")
send("curing mosshealth 70")
expandAlias("aconfig jab")