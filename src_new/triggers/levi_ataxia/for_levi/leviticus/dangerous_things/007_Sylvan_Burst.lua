--[[mudlet
type: trigger
name: Sylvan Burst
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Misc Tracking
- Warnings
- Dangerous Things
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
- pattern: ^Sweat breaking out on the forehead of \w+ is your only warning before a bolt of lightning leaps down from on high,
    slamming into you and electrifying every nerve in a synchronised wave of agony.$
  type: 1
]]--

ataxia_boxEcho("YOU GON DIE IF YOU DONT SHIELD", "NavajoWhite:DimGrey")
send("cq all;cq all;cq all")