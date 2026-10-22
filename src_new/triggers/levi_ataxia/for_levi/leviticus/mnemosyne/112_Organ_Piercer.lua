--[[mudlet
type: trigger
name: Mnemosyne Organ Piercer
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
- pattern: ^Organ Piercer\s+\d+\s+\w+
  type: 1
]]--

-- A row in the BOONS list (name / echoes / rarity) confirms Organ Piercer is active: REND
-- has a 3% chance to strike the target's vitals for a large amount of unblockable damage.
-- The dragon basher swings REND in place of GUT while it is up (balAttack, basher/002,
-- v4.7.438). Cleared on Mnemosyne run start/end (mirrors the other boon flags).
dragonOrganPiercer = true
