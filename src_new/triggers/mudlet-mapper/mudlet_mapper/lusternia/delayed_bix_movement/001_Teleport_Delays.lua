--[[mudlet
type: trigger
name: Teleport Delays
hierarchy:
- mudlet-mapper
- Mudlet Mapper
- Lusternia
- Delayed bix movement.
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
- pattern: You run your fingers across the surface of .* and still your mind, preparing for the journey ahead.
  type: 1
- pattern: ^You reach out and touch the \w+-facing landmark of the Compass of the Basin, and the spinning needle within fixes
    on that direction. The compass begins vibrating sympathetically with strands of aether\.$
  type: 1
]]--

mmp.customwalkdelay(10)