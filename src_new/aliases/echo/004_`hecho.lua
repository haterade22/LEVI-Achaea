--[[mudlet
type: alias
name: '`hecho'
hierarchy:
- echo
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: '`hecho (.+)'
command: ''
packageName: ''
]]--

local s = matches[2]

s = string.gsub(s, "%$", "\n")
hfeedTriggers("\n" .. s .. "\n")
echo("\n")