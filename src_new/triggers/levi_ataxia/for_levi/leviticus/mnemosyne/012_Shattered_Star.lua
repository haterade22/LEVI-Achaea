--[[mudlet
type: trigger
name: Mnemosyne Shattered Star
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
- pattern: ^White Heaven's Shattered Star\s+\d+\s+\w+
  type: 1
]]--

-- A row in the BOONS list (name / echoes / rarity) confirms White Heaven's Shattered
-- Star is active: it makes MULTISLASH strike 3 extra times (6 total), so the Blademaster
-- basher swaps drawslash -> multislash while it is up. Cleared on Mnemosyne run start/end
-- (mirrors bardWarmarch). Type BOONS to re-sync if needed.
bmShatteredStar = true
