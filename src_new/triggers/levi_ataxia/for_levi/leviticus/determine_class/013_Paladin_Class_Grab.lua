--[[mudlet
type: trigger
name: Paladin Class Grab
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
- pattern: ^(\w+) excises your corruption
  type: 1
- pattern: ^(\w+) calls upon \w+ valour
  type: 1
- pattern: ^(\w+) orders \w+ eagle to attack you
  type: 1
- pattern: ^As fire surges about the righteous (\w+)
  type: 1
- pattern: ^(\w+) looms over you, all righteous wrath
  type: 1
]]--

classDetect.setAttackerClass(matches[2], "Paladin")
