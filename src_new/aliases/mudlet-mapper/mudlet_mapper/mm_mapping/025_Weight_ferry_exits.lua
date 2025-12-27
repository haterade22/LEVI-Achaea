--[[mudlet
type: alias
name: Weight ferry exits
hierarchy:
- mudlet-mapper
- Mudlet Mapper
- mm Mapping
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^weight ferry exits$
command: ''
packageName: ''
]]--

local ferryCommands = {
  ["buy passage to"] = {"achaea"},
  ["takeoff to"] = {"starmourn"},
  ["station transfer to"] = {"starmourn"}
}
local c = 0
local weight = 200
for area in pairs(mmp.areatabler) do
  local rooms = getAreaRooms(area) or {}
  for i = 0, #rooms do
    local exits = getSpecialExits(rooms[i] or 0)
    if exits and next(exits) then
      for exit, cmd in pairs(exits) do
        if type(cmd) == "table" then
          cmd = next(cmd)
        end
        local lowerCommand = cmd:lower()
        local found = false
        for ferryCommand, games in pairs(ferryCommands) do
          if table.contains(games, mmp.game) and lowerCommand:find(ferryCommand, 1, true) then
            found = true
            break
          end
        end
        if found then
          setExitWeight(rooms[i], cmd, weight)
          mmp.echo(
            "Weighted " .. cmd .. " going to " .. rooms[i] .. " (" .. getRoomName(rooms[i]) .. ")."
          )
          c = c + 1
        end
      end
    end
  end
end
mmp.echo(
  string.format(
    "%s ferry exits weighted to %s (so we don't take them over too short distances).", c, weight
  )
)