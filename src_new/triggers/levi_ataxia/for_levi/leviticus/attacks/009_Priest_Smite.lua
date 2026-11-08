--[[mudlet
type: trigger
name: Priest Smite
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
- pattern: ^(\w+) utters a prayer and smites your (.+) with (.+)\.$
  type: 1
]]--

-- priest_selfLimbHit (self_limb_tracking/001): this called the misspelt priest_selftLimbHit,
-- which nothing defines, so every smite threw.
priest_selfLimbHit(matches[3])