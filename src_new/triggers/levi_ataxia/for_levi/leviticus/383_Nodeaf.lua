--[[mudlet
type: trigger
name: Nodeaf
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Third Person
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
- pattern: The songblessing unleashes a stunning percussive blast.
  type: 3
- pattern: The songblessing upon the rapier sings out with a piercing high note.
  type: 3
- pattern: The songblessing unleashes a strident note.
  type: 3
]]--

tAffs.deafness = false
confirmAffV2("undeaf")

ataxia.bardStuff.tunesmith = "pesante"