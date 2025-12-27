--[[mudlet
type: trigger
name: GMCP Rooms
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- ZulahGUI - Saonji Edit
- zGUI Redux
- Wilderness Map
- GMCP Map Catchers
attributes:
  isActive: 'yes'
  isFolder: 'no'
  isTempTrigger: 'no'
  isMultiline: 'yes'
  isPerlSlashGOption: 'no'
  isColorizerTrigger: 'no'
  isFilterTrigger: 'no'
  isSoundTrigger: 'no'
  isColorTrigger: 'no'
  isColorTriggerFg: 'no'
  isColorTriggerBg: 'no'
triggerType: 0
conditonLineDelta: 0
mStayOpen: 0
mCommand: ''
packageName: ''
mFgColor: '#ff0000'
mBgColor: '#ffff00'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
patterns:
- pattern: return gmcp.Room.Info.num < 2121028
  type: 4
- pattern: return gmcp.Room.Info.num > 0
  type: 4
]]--

if zgui.map.current ~= "Mapper" then
  zgui.map[zgui.map.current]:hide()
end
zgui.map.current = "Mapper"
zgui.map["Mapper"]:show()