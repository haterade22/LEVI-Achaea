--[[mudlet
type: trigger
name: Lift interaction failed
hierarchy:
- mudlet-mapper
- Mudlet Mapper
- Starmourn
- Lifts
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
- pattern: The lift is currently in motion and the interface is locked down.
  type: 3
- pattern: You may not exit the lift while it is in motion if you wish to remain in one piece.
  type: 3
- pattern: The lift is already moving, further attempts will not speed up the process.
  type: 3
]]--

mmp.customwalkdelay(6)
mmp.deleteLineP()