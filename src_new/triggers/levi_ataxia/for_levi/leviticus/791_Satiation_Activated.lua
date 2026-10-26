--[[mudlet
type: trigger
name: Satiation Activated
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Basher
- Bashing
- Basher Lines
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
- pattern: ^You begin concentrating on efficient digestion\.$
  type: 1
]]--

-- SATIATION (Survival, AB 1390) activated (user, 2026-10-26). The eat window is open. GMCP
-- Defences.Add stays the proof of the defence; this line only tells a failed attempt which half
-- failed (misc_scripts/022, ataxia_satiationUnconfirmed).
if ataxia_satiationActivated then ataxia_satiationActivated() end
