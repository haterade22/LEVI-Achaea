--[[mudlet
type: trigger
name: Runewarden Class Grab
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
- pattern: ^(\w+) sketches a rune upon you
  type: 1
- pattern: ^(\w+) touches a rune on the ground and it flares
  type: 1
- pattern: ^(\w+) orders \w+ falcon to attack you
  type: 1
- pattern: ^Cold blue flames wreathe (\w+)'s runeblade
  type: 1
]]--

classDetect.setAttackerClass(matches[2], "Runewarden")
