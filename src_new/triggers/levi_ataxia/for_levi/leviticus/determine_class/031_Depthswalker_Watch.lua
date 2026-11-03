--[[mudlet
type: trigger
name: Depthswalker Watch
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
- pattern: ^(\w+) reaches past you, plunging .+ into your shadow
  type: 1
- pattern: ^(\w+) delivers a lightning-fast strike to you with
  type: 1
- pattern: ^(\w+) swings .+ scythe at you
  type: 1
- pattern: ^As the scythe comes away, the writhing figure of your shadow clings to the blade\.$
  type: 1
- pattern: '^Drawing a shadow from a bone phylactery, (\w+) raises '
  type: 1
- pattern: ^You feel a deep, piercing agony, that radiates outward from the centre of your chest
  type: 1
- pattern: ^You have been slain by
  type: 1
]]--

-- Display only (levi_scripts/class_detect/002).
dwWatch.onLine(matches[1], matches[2])
