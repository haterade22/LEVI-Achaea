--[[mudlet
type: trigger
name: Distortion Cast
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Mnemosyne
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
mFgColor: '#ff0000'
mBgColor: '#ffff00'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
packageName: ''
patterns:
- pattern: ^Bending your considerable will upon the temporal flow, you distort its nature within this location\.$
  type: 1
]]--

-- CONFIRMATION that CHRONO DISTORTION landed (captured live 2026-08-12). 300 age is a large
-- spend and the once-per-room guard is stamped OPTIMISTICALLY at send, so this line is what turns
-- the guess into a fact -- and, like arc's fire line, it is the only proof of life the ability
-- has: distortion is a persistent room effect with no cooldown feed, so without this nothing
-- would ever know whether it worked.
if ataxiaBasher_dwDistortMark then ataxiaBasher_dwDistortMark(false) end
