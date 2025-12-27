--[[mudlet
type: alias
name: Show ferry rooms
hierarchy:
- mudlet-mapper
- Mudlet Mapper
- mm Mapping
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^fr show$
command: ''
packageName: ''
]]--

mmp.echo("Ferry rooms available:")
if not next(mmp.ferry_rooms) then  mmp.echo("(none)") return end

for k, _ in pairs(mmp.ferry_rooms) do
  mmp.echo(string.format("  (%d) - %s\n", k, getRoomName(k)))
end