--[[mudlet
type: trigger
name: Mnemosyne Krenindalan Storm
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
- pattern: ^Krenindalan Storm\s+\d+\s+\w+
  type: 1
]]--

-- A row in the BOONS list (name / echoes / rarity) confirms Krenindalan Storm is active: each
-- BREATHSTORM tick deals unblockable damage to every denizen in the room while we stay. The
-- dragon basher casts it once in each room (ataxiaBasher_dragonStormPick, basher/002, v4.7.442).
-- Cleared on Mnemosyne run start/end (mirrors the other boon flags).
dragonKrenindalan = true
