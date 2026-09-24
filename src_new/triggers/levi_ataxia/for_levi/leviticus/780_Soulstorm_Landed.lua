--[[mudlet
type: trigger
name: Soulstorm Landed
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
- pattern: ^You call forth an unholy tide of necromantic essence and release it, engulfing .+ in a profane soulstorm\.$
  type: 1
]]--

-- The soul is profaned (live 2026-09-24). One storm per denizen is the whole rule -- the boon's
-- value is the DEBUFF sitting on that mob, not a hit we repeat -- so this marks the target we sent
-- for and the rider never picks it again. The line prints with or without Deathtempest, so it
-- proves nothing about the boon and does not latch it.
if ataxiaBasher_soulstormLanded then ataxiaBasher_soulstormLanded() end
