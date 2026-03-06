--[[mudlet
type: alias
name: BECKON TOGGLE
hierarchy:
- Levi_Ataxia
- Ataxia
- Config
- Toggles
attributes:
  isActive: 'no'
  isFolder: 'no'
regex: '^beck(?: (\w+)|)$'
command: ''
packageName: ''
]]--

if beckonmode then
	beckonmode = false
	cecho(" NOT BECKONING ")
else
	beckonmode = true
	cecho(" BECKONING ")
end