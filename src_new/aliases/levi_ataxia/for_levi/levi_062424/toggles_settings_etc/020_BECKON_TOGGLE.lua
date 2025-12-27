--[[mudlet
type: alias
name: BECKON TOGGLE
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- Ataxia-DownloadThis
- Ataxia
- Installation / Configuration
- Toggles/Settings/Etc.
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