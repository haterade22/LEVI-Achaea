--[[mudlet
type: trigger
name: Depthswalker Class Grab
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
- pattern: ^Shadows coalesce around you at the bidding of (\w+)
  type: 1
- pattern: ^(\w+) intones a word of power
  type: 1
- pattern: ^(\w+) begins dedicating part of \w+ attention to predicting where you shall
  type: 1
]]--

classDetect.setAttackerClass(matches[2], "Depthswalker")
