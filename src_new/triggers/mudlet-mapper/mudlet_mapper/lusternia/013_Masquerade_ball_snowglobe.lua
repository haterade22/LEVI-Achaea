--[[mudlet
type: trigger
name: Masquerade ball snowglobe
hierarchy:
- mudlet-mapper
- Mudlet Mapper
- Lusternia
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
conditonLineDelta: 2
mStayOpen: 0
mCommand: ''
packageName: ''
mFgColor: '#ff0000'
mBgColor: '#ffff00'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
patterns:
- pattern: ^You trace the name of \w+ on the surface of a splendid masquerade ball snowglobe, and then shake the globe vigorously\.
    As the swirling particles within clear, you see the vague outline of .+?\.$
  type: 1
- pattern: 'You see the following in detail:'
  type: 3
- pattern: v(\d+)
  type: 1
]]--

mmp.gotoRoom(multimatches[3][2])