--[[mudlet
type: alias
name: autotest
hierarchy:
- Levi_Ataxia
- Combat
- Enemy Management
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^aauto (.*)$
command: ''
packageName: ''
]]--

if matches[2] == "bleedfork" then
  autopostate = true
  apostack = "bleedfork"
else
  autopostate = false
  cecho("\nautopostate off!")
end