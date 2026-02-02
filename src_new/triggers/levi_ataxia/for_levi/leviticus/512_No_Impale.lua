--[[mudlet
type: trigger
name: No Impale
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes Other
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
- pattern: ^With a look of agony on \w+ face, (\w+) manages to writhe \w+ free of the weapon which impaled \w+.$
  type: 1
- pattern: ^With a vicious snarl you carve a merciless swathe through the steaming guts of (\w+), who gurgles and chokes as
    you withdraw your dripping blade, glistening with gore.$
  type: 1
]]--

tAffs.impaled = false
if removeAffV3 then removeAffV3("impaled") end
timpale = false