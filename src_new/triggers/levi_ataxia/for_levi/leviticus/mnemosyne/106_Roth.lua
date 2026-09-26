--[[mudlet
type: trigger
name: Roth
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
packageName: ''
mFgColor: '#ff0000'
mBgColor: '#ffff00'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
patterns:
- pattern: ^Roth\s+\d+\s+\w+
  type: 1
]]--

-- A row in the BOONS list confirms Roth is active (v4.7.360) -- the Psion COMBO boon (Razor Clarity
-- + Bloodletter's Fury):
--
--   "Your emulation wrath ability now has a cooldown of 30 seconds, and only requires you to be
--    under 75% of your maximum health."
--
-- The Psion round then sends ENACT WRATH below 75% health every ~35s (basher/002). Only inside the
-- tower (the gate every boon row carries since v4.7.351). Cleared on Mnemosyne run start/end.
if ataxiaBasher and ataxiaBasher.inMnemosyne then psionRoth = true end
