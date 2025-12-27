--[[mudlet
type: trigger
name: init limb target
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- limb.1.2
- Limb
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
- pattern: '^Your target is now\: (\w+) \(an adventurer\)$'
  type: 1
- pattern: '^Your target is now\: (\w+) \(a denizen\)$'
  type: 1
]]--

lb.initTarget(matches[2])