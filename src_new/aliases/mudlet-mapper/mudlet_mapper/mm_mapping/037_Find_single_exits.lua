--[[mudlet
type: alias
name: Find single exits
hierarchy:
- mudlet-mapper
- Mudlet Mapper
- mm Mapping
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^find single exits$
command: ''
packageName: ''
]]--

local c = 0

local getAreaRooms, getRoomExits, contains, echoLink, getRoomEnv, envidsr =
  getAreaRooms, getRoomExits, table.contains, echoLink, getRoomEnv, mmp.envidsr

for area, id in pairs(getAreaTable()) do
  for _, roomid in pairs(getAreaRooms(id)) do
    local exits = getRoomExits(roomid)
    for dir, otherroom in pairs(exits) do
      local otherexits = getRoomExits(otherroom) or {}
      if not contains(otherexits, roomid) then
        echoLink(string.format("%s -> %s is oneway (%s->%s type)\n", roomid, otherroom,
          (envidsr and envidsr[getRoomEnv(roomid)] or "?"),
          (envidsr and envidsr[getRoomEnv(otherroom)] or "?")),
        [[mmp.gotoRoom(]]..roomid..[[)]], "Click to go to the start room "..roomid, true)
        c = c + 1
     end
    end
  end
end

mmp.echo(string.format("Found %s oneways.%s", c, (c > 10 and " Have fun. Click on lines to go to the rooms." or "")))