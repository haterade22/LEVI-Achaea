--[[mudlet
type: alias
name: Room list
hierarchy:
- mudlet-mapper
- Mudlet Mapper
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: '^room list(?: (.+))?$'
command: ''
packageName: ''
]]--

mmp.echoRoomList(matches[2] or mmp.areatabler[getRoomArea(mmp.currentroom)])