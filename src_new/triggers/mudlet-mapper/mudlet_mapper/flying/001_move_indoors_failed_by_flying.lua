--[[mudlet
type: trigger
name: move indoors failed by flying
hierarchy:
- mudlet-mapper
- Mudlet Mapper
- Flying
attributes:
  isActive: 'yes'
  isFolder: 'no'
  isTempTrigger: 'no'
  isMultiline: 'no'
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
- pattern: You must land before you can move indoors.
  type: 3
]]--

--this will force land
--may be preferable to fail pathfinding or have option to determine users desire

if mmp.game == "starmourn" then
		send("queue land")
		mmp.customwalkdelay(4)
end
