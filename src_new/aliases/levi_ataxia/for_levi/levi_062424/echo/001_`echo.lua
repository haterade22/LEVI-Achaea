--[[mudlet
type: alias
name: '`echo'
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- echo
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: '`echo (.+)'
command: ''
packageName: ''
]]--

local s = matches[2]

s = string.gsub(s, "%$", "\n")
feedTriggers("\n" .. s .. "\n")
echo("\n")