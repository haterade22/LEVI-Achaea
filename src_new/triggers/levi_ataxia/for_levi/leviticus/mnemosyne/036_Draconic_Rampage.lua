--[[mudlet
type: trigger
name: Mnemosyne Draconic Rampage
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
- pattern: ^Draconic Rampage\s+\d+\s+\w+
  type: 1
]]--

-- A row in the BOONS list (name / echoes / rarity) confirms Draconic Rampage is
-- active: TRAMPLE deals a large amount of cutting damage to ALL denizens in the
-- room, on a 40s proc cooldown. The dragon basher spends the balance swing on
-- TRAMPLE at 2+ denizens whenever the proc is ready (ataxiaBasher_dragonRampagePick,
-- basher/002). Cleared on Mnemosyne run start/end (mirrors the other boon flags).
-- Type BOONS to re-sync if needed.
dragonRampage = true
