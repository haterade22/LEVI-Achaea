--[[mudlet
type: alias
name: View roomID or area
hierarchy:
- mudlet-mapper
- Mudlet Mapper
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^mmap ?(.+)?$
command: ''
packageName: ''
]]--

local where = matches[2]

if not where then
	centerview(mmp.currentroom)
elseif tonumber(where) then -- view a room ID
	centerview(where)
else -- view an area
	mmp.viewArea (where)
end