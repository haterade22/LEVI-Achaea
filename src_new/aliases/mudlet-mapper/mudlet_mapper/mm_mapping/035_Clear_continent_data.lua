--[[mudlet
type: alias
name: Clear continent data
hierarchy:
- mudlet-mapper
- Mudlet Mapper
- mm Mapping
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^clear continent data$
command: ''
packageName: ''
]]--

if not mmp.wipingcontinents then
  mmp.wipingcontinents = true
  mmp.echo("Are you sure you want to wipe all continent data? If yes, do this again.")
  return
end
mmp.wipingcontinents = nil

local toserialize = yajl.to_string{}
setRoomUserData(1, "areaContinents", toserialize)
mmp.echo("Wiped all continents data.")