--[[mudlet
type: alias
name: TELL IMPASTUS
hierarchy:
- Levi_Ataxia
- General
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^ti$
command: ''
packageName: ''
]]--

send("tell "..ataxia.getMount().." come here")