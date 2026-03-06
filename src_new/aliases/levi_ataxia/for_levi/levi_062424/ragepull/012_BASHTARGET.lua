--[[mudlet
type: alias
name: BASHTARGET
hierarchy:
- Levi_Ataxia
- RAGEPULL
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^bt (\w+)$
command: ''
packageName: ''
]]--

bashtarget = matches[2]
ataxia_boxEcho(" TARGETTING "..bashtarget.." ")