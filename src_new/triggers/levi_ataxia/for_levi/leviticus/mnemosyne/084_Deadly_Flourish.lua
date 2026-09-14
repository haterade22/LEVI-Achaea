--[[mudlet
type: trigger
name: Mnemosyne Deadly Flourish
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
- pattern: ^Deadly Flourish\s+\d+\s+\w+
  type: 1
]]--

-- A row in the BOONS list (name / echoes / rarity) confirms Deadly Flourish is active: BLADE
-- FLOURISH may now be used on a denizen and deals additional cutting damage to every denizen in
-- the room, once every 15 seconds. The Bard basher spends a balance on it whenever that clock is
-- up (`ataxiaBasher_bardFlourish`, basher/002). Cleared on Mnemosyne run start/end, like every
-- other boon flag. Type BOONS to re-sync if needed.
mnemDeadlyFlourish = true
