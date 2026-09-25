--[[mudlet
type: trigger
name: Foresight Refused
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
- pattern: Your mind has not yet recovered enough to pierce the fabric of time once again.
  type: 3
]]--

-- Foresight is still on cooldown (user, 2026-09-25: "I think there is maybe a 30 seconds cooldown on
-- it"). We do not know the remainder, so the basher tries again in 5s (v4.7.359).
if ataxiaBasher_psionForesightRefused then ataxiaBasher_psionForesightRefused() end
