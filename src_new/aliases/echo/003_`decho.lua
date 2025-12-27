--[[mudlet
type: alias
name: '`decho'
hierarchy:
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