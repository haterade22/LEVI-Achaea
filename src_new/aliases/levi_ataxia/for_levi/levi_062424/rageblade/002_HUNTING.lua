--[[mudlet
type: alias
name: HUNTING
hierarchy:
- Levi_Ataxia
- Artefacts
- Rageblade
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^rage$
command: ''
packageName: ''
]]--

send("wield shield rageblade")
send("curing siphealth 30")
send("curing mosshealth 25")
expandAlias("aconfig jab")