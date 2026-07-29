--[[mudlet
type: trigger
name: Mnemosyne Flashforward
hierarchy:
- Levi_Ataxia
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
- pattern: ^Flashforward\s+\d+\s+\w+
  type: 1
]]--

-- A row in the BOONS list (name / echoes / rarity) confirms Flashforward is active:
-- "You deal 20% bonus damage while you possess the chrono blur defence." The
-- Depthswalker basher keeps CHRONO BLUR up while this is set -- an equilibrium rider
-- paid in AGE (age-capped by ataxiaBasher.dwAgeCap), not the word balance, so it never
-- competes with nakail or the Terminus buffs (ataxiaBasher_dwFlashforward, basher/002).
-- Cleared on Mnemosyne run start/end. Type BOONS to re-sync if needed.
dwFlashforward = true
