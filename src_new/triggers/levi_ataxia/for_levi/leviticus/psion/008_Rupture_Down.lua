--[[mudlet
type: trigger
name: Rupture Down
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Class Stuff
- Psion
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
- pattern: Distractions reassert themselves, your mental clarity returning to mundane levels.
  type: 3
]]--

-- The user gave this as the Bloodletter/rupture DOWN line (2026-09-26). The charge is gone: the
-- keeper re-enacts rupture on the next round (v4.7.361, basher/002). The wording reads like clarity's,
-- but the user confirmed: "It is rupture dropping."
if ataxiaBasher_psionRuptureSeen then ataxiaBasher_psionRuptureSeen(false) end
