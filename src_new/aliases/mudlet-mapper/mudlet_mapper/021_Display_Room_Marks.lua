--[[mudlet
type: alias
name: Display Room Marks
hierarchy:
- mudlet-mapper
- Mudlet Mapper
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^room marks$
command: ''
packageName: ''
]]--

local tmp= getRoomUserData(1, "gotoMapping")
if tmp~="" then
	local maptable = yajl.to_value(tmp) or {}
    local sortedkeys = {}
    for k in pairs(maptable) do sortedkeys[#sortedkeys+1] = k end
    table.sort(sortedkeys)

    mmp.echo("Known marks in this map:")
    if next(maptable) then
      for i = 1, #sortedkeys do echo(string.format("  %-21s  %s\n", tostring(sortedkeys[i]), tostring(maptable[sortedkeys[i]]))) end
    else
      echo("  (none)\n")
    end
else
	mmp.echo("No marks are recorded in this map.")
end