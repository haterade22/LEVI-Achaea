--[[mudlet
type: trigger
name: SnB Slice
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
- pattern: ^The blade of (\w+) is a blur as \w+ moves forward, slicing into your (.+).$
  type: 1
]]--

snb_selfLimbHit(matches[3])