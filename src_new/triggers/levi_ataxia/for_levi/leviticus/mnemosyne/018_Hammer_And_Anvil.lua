--[[mudlet
type: trigger
name: Mnemosyne Hammer and Anvil
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
- pattern: ^Hammer and Anvil\s+\d+\s+\w+
  type: 1
]]--

-- A row in the BOONS list (name / echoes / rarity) confirms Hammer and Anvil is active:
-- the Smith's raw strength lets attacks bypass denizen shields, so the basher skips the
-- whole shield reaction (raze path + shield-swap in 336_Mob_Shielded). Cleared on
-- Mnemosyne run start/end (mirrors bmShatteredStar). Type BOONS to re-sync if needed.
mnemHammerAnvil = true
ataxiaBasher.shielded = false
