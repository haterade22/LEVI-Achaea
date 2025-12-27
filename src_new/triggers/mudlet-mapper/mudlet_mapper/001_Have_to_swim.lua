--[[mudlet
type: trigger
name: Have to swim
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
- pattern: There's water ahead of you. You'll have to swim in that direction to make it through.
  type: 3
- pattern: 'There''s water ahead of you. You''ll have to swim in that direction to make it '
  type: 3
- pattern: 'There''s water ahead of you. You''ll have to SWIM '
  type: 2
- pattern: You'll have to swim to make it through the water in that direction.
  type: 3
- pattern: The water is too deep for you to walk that way, you must swim.
  type: 3
- pattern: You'll have to SWIM
  type: 2
]]--

mmp.swim()