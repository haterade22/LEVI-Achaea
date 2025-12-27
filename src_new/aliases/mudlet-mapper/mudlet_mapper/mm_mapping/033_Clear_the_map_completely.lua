--[[mudlet
type: alias
name: Clear the map completely
hierarchy:
- mudlet-mapper
- Mudlet Mapper
- mm Mapping
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^map delete all$
command: ''
packageName: ''
]]--

if not mmp.map_delete_warning then
  mmp.echo("Are you really, really, really sure you want to delete all of the map to go to a blank state? Do the command again if you're certain.")
  mmp.map_delete_warning = true
  return
end

mmp.echo("Okay, deleting...")

tempTimer(.1, function()
  for name, id in pairs(getAreaTable()) do
    deleteArea(tonumber(id))
  end

  mmp.echo("Deleted everything. It's all gone.")
  mmp.map_delete_warning = nil
  centerview(1)
end)