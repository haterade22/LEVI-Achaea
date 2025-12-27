--[[mudlet
type: trigger
name: Rubble at the exit
hierarchy:
- mudlet-mapper
- Mudlet Mapper
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
- pattern: You begin to slowly clamber over the rubble that blocks your way.
  type: 3
- pattern: You begin to slowly clamber over a pile of rubble that blocks your way.
  type: 3
- pattern: You start plodding carefully across the constructed trenches.
  type: 3
- pattern: You struggle to climb over the snow drift in your way.
  type: 3
- pattern: You struggle to climb over the sand dune in your way.
  type: 3
- pattern: You slowly clamber over the rubble in your path.
  type: 3
]]--

mmp.customwalkdelay(2)