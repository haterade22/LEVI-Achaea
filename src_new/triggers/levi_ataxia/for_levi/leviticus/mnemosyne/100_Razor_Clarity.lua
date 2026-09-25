--[[mudlet
type: trigger
name: Razor Clarity
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
- pattern: ^Razor Clarity\s+\d+\s+\w+
  type: 1
]]--

-- A row in the BOONS list confirms Razor Clarity is active (v4.7.349):
--
--   "You deal 50% bonus damage and have 2% bonus critical chance while benefitting from the
--    emulation clarity defence."
--
-- Same shape as Bloodletter's Fury beside it: the boon pays out only while a defence stands, so
-- the round keeps `clarity` up on equilibrium (`ataxiaBasher_psionEmulationKeepers`, basher/002).
--
-- Cleared on Mnemosyne run start/end. Type BOONS to re-sync if needed.
-- Only inside the tower (v4.7.351, deep review) -- the same gate the generic row trigger
-- (mnemosyne/013) applies, so a list printed outside a run arms nothing.
if ataxiaBasher and ataxiaBasher.inMnemosyne then psionRazorClarity = true end
