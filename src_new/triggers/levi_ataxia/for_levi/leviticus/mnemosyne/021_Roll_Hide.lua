--[[mudlet
type: trigger
name: Mnemosyne Roll Hide
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
- pattern: ^Roll Hide\s+\d+\s+\w+
  type: 1
]]--

-- A row in the BOONS list (name / echoes / rarity) confirms Roll Hide is active:
-- tumbling out of a room sheds ALL pursuing denizens. Captured now for the swarm
-- module's stage-2 panic abort (config key defined when that branch ships).
-- Cleared on Mnemosyne run start/end (mirrors bmShatteredStar). Type BOONS to
-- re-sync if needed.
mnemRollHide = true
