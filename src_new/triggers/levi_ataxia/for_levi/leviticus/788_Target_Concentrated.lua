--[[mudlet
type: trigger
name: Target Concentrated
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Remove Afflictions
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
- pattern: ^(\w+)'s eyes lose their focus suddenly\.
  type: 1
]]--

-- v4.7.415: the target's CONCENTRATE. Mystor's logs (2026-10-11) show it straight after the
-- opponent's own `concentrate` (Sapience), 11 times. It cures DISRUPTED and nothing else: an
-- Infernal concentrated MIND DISRUPT away within a second 8 times out of 9, while
-- telepathy_tekura/007 kept `disrupted` on its target for a flat 10 s.
if isTargeted(matches[2]) then
  erAff("disrupted")
end
