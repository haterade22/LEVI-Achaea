--[[mudlet
type: alias
name: Add/remove a ferry room
hierarchy:
- mudlet-mapper
- Mudlet Mapper
- mm Mapping
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^fr (\d+) (add|remove)$
command: ''
packageName: ''
]]--

local room = tonumber(matches[2])

if matches[3] == "add" then
  if mmp.ferry_rooms[room] then
    mmp.echo("Ferry room #"..room.." is already recorded as such.") return
  else
    mmp.ferry_rooms[room] = true; mmp.echo("Added #"..room.." to be a ferry room.")
  end
else
  if not mmp.ferry_rooms[room] then
    mmp.echo("Room #"..room.." isn't a ferry one already.") return
  else
    mmp.ferry_rooms[room] = nil; mmp.echo("Removed #"..room.." from being a ferry room.")
  end
end

local keys = {}; for k,_ in pairs(mmp.ferry_rooms) do keys[#keys+1] = k end

setRoomUserData(1, "ferry rooms", yajl.to_string(keys))