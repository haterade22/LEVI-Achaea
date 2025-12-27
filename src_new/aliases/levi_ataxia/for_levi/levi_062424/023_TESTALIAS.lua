--[[mudlet
type: alias
name: TESTALIAS
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- LeviticusREG
- Leviticus
- General
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^testalias (\d+) (\d+)$
command: ''
packageName: ''
]]--

send("say I think "..matches[2].." is better than "..matches[3].." huh?")