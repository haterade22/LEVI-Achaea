--[[mudlet
type: alias
name: Get dirs
hierarchy:
- mudlet-mapper
- Mudlet Mapper
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: '^showpath(?: (\d+))?(?: (\d+))?$'
command: ''
packageName: ''
]]--

if not matches[2] and not matches[3] then
  mmp.echo("Where do you want to showpath to?")
elseif matches[2] and not matches[3] then
  mmp.echoPath(mmp.currentroom, matches[2])
else
  mmp.echoPath(matches[2], matches[3])
end