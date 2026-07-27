--[[mudlet
type: trigger
name: Mnemosyne Might Of Sycaerunax
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
- pattern: ^Might of Sycaerunax\s+\d+\s+\w+
  type: 1
]]--

-- A row in the BOONS list (name / echoes / rarity) confirms Might of Sycaerunax is
-- active: draconic BLAST does +25% damage and the breath weapon PERSISTS -- no
-- re-summon needed after use. The dragon basher drops the ";summon <ele>" from its
-- blast weave and shielded reblast while this is up (ataxiaBasher_dragonBashing,
-- basher/002). Cleared on Mnemosyne run start/end (mirrors the other boon flags).
-- Type BOONS to re-sync if needed.
dragonMightSycaerunax = true
