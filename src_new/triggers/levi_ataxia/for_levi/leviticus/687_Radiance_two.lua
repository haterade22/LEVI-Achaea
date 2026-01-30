--[[mudlet
type: trigger
name: Radiance two
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Misc Tracking
- Warnings
- Warnings
attributes:
  isActive: 'yes'
  isFolder: 'no'
  isTempTrigger: 'no'
  isMultiline: 'yes'
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
- pattern: A shimmering image of the face of
  type: 2
- pattern: ^A shimmering image of the face of (\w+) appears fleetingly before you, frowning in concentration\.$
  type: 1
]]--

lastradiancer = multimatches[2][2]
tempTimer(28, [[lastradiancer = nil]])

cecho("\n<red>".. multimatches[2][2].." radiancing you (2/7)")
ataxia_setWarning(multimatches[2][2].." radiancing", 2)
