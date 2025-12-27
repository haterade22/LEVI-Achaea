--[[mudlet
type: alias
name: '`decho'
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- echo
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: '`decho (.+)'
command: ''
packageName: ''
]]--

local s = matches[2]

s = string.gsub(s, "%$", "\n")
dfeedTriggers("\n" .. s .. "\n")
echo("\n")