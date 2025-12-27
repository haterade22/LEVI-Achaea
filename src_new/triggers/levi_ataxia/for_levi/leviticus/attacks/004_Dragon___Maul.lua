--[[mudlet
type: trigger
name: Dragon / Maul
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Self Limb Tracking
- Attacks
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
- pattern: ^[A-Z][a-z]+ springs forwards and mauls your (.+)\.$
  type: 1
- pattern: ^([A-Z][a-z]+) lunges forward with long, flashing claws extended, tearing down to the bones of your (.+)\.$
  type: 1
]]--

 quarterHit_selfLimbHit(matches[3])