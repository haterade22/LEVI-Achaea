--[[mudlet
type: alias
name: '`cecho'
hierarchy:
- Levi_Ataxia
- echo
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: '`cecho (.+)'
command: ''
packageName: ''
]]--

local s = matches[2]

s = string.gsub(s, "%$", "\n")
cfeedTriggers("\n" .. s .. "\n")
echo("\n")