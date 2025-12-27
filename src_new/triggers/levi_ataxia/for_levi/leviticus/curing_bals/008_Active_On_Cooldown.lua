--[[mudlet
type: trigger
name: Active On Cooldown
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Curing Stuff
- Curing Bals
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
- pattern: You have not yet recovered enough to purge your great form of afflictions.
  type: 3
- pattern: You may not purge your lungs again as of this time.
  type: 3
- pattern: You may not shrug again so soon.
  type: 3
- pattern: You have not recovered enough to boil your blood again as of yet.
  type: 3
- pattern: You may not cleanse your form of weakness quite so soon after doing so previously.
  type: 3
]]--

ataxiaTemp.activeCureUsed = true