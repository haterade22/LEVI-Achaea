--[[mudlet
type: alias
name: 'SLC Set # of Hits Needed'
hierarchy:
- Levi_Ataxia
- Classes
- slc
attributes:
  isActive: 'no'
  isFolder: 'no'
regex: ^cset (\w+) (\d+)$
command: ''
packageName: ''
]]--

SLC_set_attack(matches[2],matches[3])
