--[[mudlet
type: trigger
name: Bloodletter's Fury
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
- pattern: ^Bloodletter's Fury\s+\d+\s+\w+
  type: 1
]]--

-- A row in the BOONS list confirms Bloodletter's Fury is active (v4.7.349):
--
--   "Your emulation rupture ability is now effective against denizens. While you possess the
--    rupturesight defence, your weaving attacks against denizens will now deal unblockable
--    damage and 50% increased base damage, and you will recover balance 20% faster."
--
-- Unblockable, half again the damage and a fifth off the balance -- for as long as ONE defence
-- stands. So the Psion round keeps `rupturesight` up on equilibrium, which its weaves leave
-- idle (`ataxiaBasher_psionEmulationKeepers`, basher/002).
--
-- Cleared on Mnemosyne run start/end. Type BOONS to re-sync if needed.
-- Only inside the tower (v4.7.351, deep review) -- the same gate the generic row trigger
-- (mnemosyne/013) applies, so a list printed outside a run arms nothing.
if ataxiaBasher and ataxiaBasher.inMnemosyne then psionBloodletter = true end
