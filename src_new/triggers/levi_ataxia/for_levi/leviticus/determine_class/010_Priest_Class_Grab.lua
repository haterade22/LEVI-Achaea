--[[mudlet
type: trigger
name: Priest Class Grab
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Curing Stuff
- Priority Management
- Determine Class
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
- pattern: ^(\w+) stares at you, eyes smouldering with dark intent\.$
  type: 1
- pattern: ^(\w+) condemns you to see the fate of the enemies of creation\.$
  type: 1
- pattern: ^(\w+) directs a dazzling ray of light at you\.$
  type: 1
- pattern: ^(\w+) commands you to refrain from gluttony\.$
  type: 1
- pattern: ^Raising an imperious hand, (\w+) condemns you to suffer the sin of sloth\.$
  type: 1
]]--

classDetect.setAttackerClass(matches[2], "Priest")
