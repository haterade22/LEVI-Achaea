--[[mudlet
type: trigger
name: Active Ready
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
- pattern: You may channel alchemical energy to heal yourself once again.
  type: 3
- pattern: You may purge your lungs once again.
  type: 3
- pattern: You may heal another affliction.
  type: 3
- pattern: Your body has recovered enough to shrug afflictions once again.
  type: 3
- pattern: You may cure your afflictions with spiritual energy once again.
  type: 3
- pattern: You may accelerate time to cleanse your afflictions once again.
  type: 3
- pattern: You may purge your great form of afflictions once again.
  type: 3
- pattern: You may boil your blood once again.
  type: 3
- pattern: You may purge yourself of weakness once again.
  type: 3
]]--

ataxiaTemp.activeCureUsed = nil

ataxia_lockBreak()