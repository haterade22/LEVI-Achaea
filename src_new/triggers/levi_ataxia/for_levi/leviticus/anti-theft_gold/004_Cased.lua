--[[mudlet
type: trigger
name: Cased
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Misc Triggers
- Anti-theft/Gold
attributes:
  isActive: 'yes'
  isFolder: 'no'
  isTempTrigger: 'no'
  isMultiline: 'no'
  isPerlSlashGOption: 'no'
  isColorizerTrigger: 'yes'
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
mFgColor: '#000000'
mBgColor: '#ff0000'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
patterns:
- pattern: A shadowy figure circles you, taking inventory of your possessions.
  type: 3
- pattern: ^A shadowy figure circles \w+, taking inventory of \w+ possessions.$
  type: 1
]]--

local sp = ataxia.settings.separator or ";"
ataxia_boxEcho("Sneaky serpent roaming about", "black:tomato")
send("queue addclear free search"..sp.."ql")
ataxiaBasher_alert("Normal")