--[[mudlet
type: alias
name: Remove Room Mark
hierarchy:
- mudlet-mapper
- Mudlet Mapper
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^room unmark (\w+)$
command: ''
packageName: ''
]]--

local tmp= getRoomUserData(1, "gotoMapping")
if tmp~="" then
  local maptable=yajl.to_value(tmp)
  if not maptable[matches[2]] then mmp.echo("Don't have such a mark in the db.") return end

  maptable[matches[2]]=nil
  local tmp2=yajl.to_string(maptable)
  setRoomUserData(1, "gotoMapping", tmp2)
  mmp.echo("Removed the "..matches[2].." mark.")
else
  mmp.echo("We don't have any marks stored anyway.")
end