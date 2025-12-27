--[[mudlet
type: alias
name: Go to ID or area
hierarchy:
- mudlet-mapper
- Mudlet Mapper
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^goto (.+)$
command: ''
packageName: ''
]]--

local where = matches[2]:lower()
local gallop
if command:ends("gallop") then
  gallop = "gallop"
  where = where:sub(1, -8)
elseif command:ends("sprint") then
  gallop = "sprint"
  where = where:sub(1, -8)
elseif command:ends("dash") then
  gallop = "dash"
  where = where:sub(1, -6)
elseif command:ends("runaway") then
  gallop = "runaway"
  where = where:sub(1, -9)
elseif command:ends("glide") then
  gallop = "glide"
  where = where:sub(1, -7)
end
if mmp.debug then
  mmp.gotoPerf = mmp.gotoPerf or createStopWatch()
  startStopWatch(mmp.gotoPerf)
end
-- goto room ID
if tonumber(where) then
  mmp.gotoRoom(where, gallop)
else
  -- goto area or feature
  local split = where:split(" ")
  if split[1] == "feature" then
	  table.remove(split, 1)
    mmp.gotoFeature(table.concat(split, " "), gallop)
  else
    if tonumber(split[#split]) then
      mmp.gotoArea(where:sub(1, -#(split[#split]) - 2), tonumber(split[#split]), gallop)
    else
      mmp.gotoArea(where, nil, gallop)
    end
  end
end
if mmp.debug then
  mmp.echo("goto alias took " .. stopStopWatch(mmp.gotoPerf) .. "s to run.")
end