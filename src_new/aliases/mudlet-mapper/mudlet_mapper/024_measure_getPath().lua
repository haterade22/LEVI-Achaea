--[[mudlet
type: alias
name: measure getPath()
hierarchy:
- mudlet-mapper
- Mudlet Mapper
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^getpath (?:from )?(\d+) (?:to )?(\d+)$
command: ''
packageName: ''
]]--

mmp = mmp or {}

mmp.getPathPerf = mmp.getPathPerf or createStopWatch()
startStopWatch(mmp.getPathPerf)

local from, to = tonumber(matches[2]), tonumber(matches[3])

getPath(from, to)

mmp.echon = mmp.echon or echo
mmp.echon("a new getPath() from "..from.." to "..to.." took "..stopStopWatch(mmp.getPathPerf).."s. There are "..#speedWalkPath.." rooms to visit in it.")
echo(" ")
echoLink("[unhighlight]", [[
  for room in pairs(mmp.getpathhighlights) do
    unHighlightRoom(room)
  end
]], "Click me to remove highlighting from getpath")

mmp.getpathhighlights = mmp.getpathhighlights or {}

for room in pairs(mmp.getpathhighlights) do
  unHighlightRoom(room)
end

mmp.getpathhighlights = {}

local r,g,b = unpack(color_table.yellow)
local br,bg,bb = unpack(color_table.yellow)
-- add the first room to the speedWalkPath, as we'd like it highlighted as well
table.insert(speedWalkPath, 1, from)
for i = 1, #speedWalkPath do
  local room = speedWalkPath[i]
  highlightRoom(room, r,g,b,br,bg,bb, 1, 255, 255)
  mmp.getpathhighlights[room] = true
end

centerview(from)