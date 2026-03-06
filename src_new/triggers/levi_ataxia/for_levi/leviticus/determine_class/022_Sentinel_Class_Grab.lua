--[[mudlet
type: trigger
name: Sentinel Class Grab
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
- pattern: ^(\w+) hurls .+ axe at you
  type: 1
- pattern: ^(\w+) commands \w+ (?:spider|wolf|hawk|bear) to attack you
  type: 1
- pattern: ^(\w+) strikes you with a quick skirmishing blow
  type: 1
- pattern: ^(\w+) cocks back \w+ arm and throws .+ axe at your
  type: 1
- pattern: ^(\w+) lays open your flesh with an expert lateral slice
  type: 1
- pattern: ^Turning with the motion of \w+ strike, (\w+) comes back around to slam
  type: 1
]]--

classDetect.setAttackerClass(matches[2], "Sentinel")
