--[[mudlet
type: trigger
name: Mnemosyne Bladed Reflexes
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
- pattern: ^Bladed Reflexes\s+\d+\s+\w+
  type: 1
]]--

-- A row in the BOONS list (name / echoes / rarity) confirms Bladed Reflexes is active:
-- 20% reduced damage while the Shindo AUGMENT state (bodyaugment defence) is up, so the
-- Blademaster basher keeps it up with SHIN AUGMENT 1 whenever it holds shin (see
-- ataxiaBasher_blademasterBashing). Cleared on Mnemosyne run start/end (mirrors
-- bmShatteredStar). Type BOONS to re-sync if needed.
bmBladedReflexes = true
