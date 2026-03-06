--[[mudlet
type: trigger
name: Bard Class Grab
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
- pattern: ^With a flourish of .+ (\w+) steps in close, \w+ blade slicing at your
  type: 1
- pattern: ^(\w+)'s paean slams into you
  type: 1
- pattern: ^(\w+)'s blade sings with a metallic song
  type: 1
- pattern: ^(\w+) continues to circle you
  type: 1
]]--

classDetect.setAttackerClass(matches[2], "Bard")
