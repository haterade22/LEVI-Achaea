--[[mudlet
type: trigger
name: Apostate Class Grab
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
- pattern: ^(\w+) stares at you, giving you the evil eye\.$
  type: 1
- pattern: ^(\w+) points \w+ blood slick daegger at you, slashing a pentagram in the air
  type: 1
- pattern: ^The whirling daegger of (\w+) plunges into your flesh\.$
  type: 1
- pattern: ^(\w+) commands \w+ baalzadeen to corrupt your soul\.$
  type: 1
]]--

classDetect.setAttackerClass(matches[2], "Apostate")
