ataxiaExtraction = ataxiaExtraction or {}
local a = gmcp.Room.Info.area 

if ataxiaExtraction[a] then
  send("queue addclear free extract "..ataxiaExtraction[a],false)
else
  send("minerals",false)
end
