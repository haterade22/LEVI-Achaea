--[[mudlet
type: trigger
name: Holo
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Misc Tracking
- Warnings
- Warnings
- Instakills
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
- pattern: fashions a holocaust globe out of pure elemental fire and arms it.
  type: 0
- pattern: ^\w+ fashions a sphere of crackling electricity and arms it\.$
  type: 1
]]--

cecho("<red>\nHOLO HOLO!!\nHOLO HOLO!!\nHOLO HOLO!!\nHOLO HOLO!!\nHOLO HOLO!!\n")
ataxia_setWarning("holocaust dropped", 2.5)	
