--[[mudlet
type: trigger
name: Occultist Class Grab
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
- pattern: ^(\w+) glows with an emerald hue and snaps \w+ fingers at you
  type: 1
- pattern: ^(\w+) throws back \w+ head and utters a string of words
  type: 1
- pattern: ^(\w+) makes a quick, sharp gesture toward you
  type: 1
- pattern: ^(\w+) passes \w+ hand in front of you
  type: 1
- pattern: ^(\w+) flings a .+ tarot card at you
  type: 1
]]--

classDetect.setAttackerClass(matches[2], "Occultist")
