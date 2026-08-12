--[[mudlet
type: trigger
name: Apostatic
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
- pattern: ^Apostatic\s+\d+\s+\w+
  type: 1
]]--

-- BOONS row (Jester). the PRIESTESS tarot damages denizens instead of healing them -- flung on a generous cooldown, since a fling may consume an inscribed card.
--
-- Handled in ataxiaBasher_jesterBashing (basher/002). Cleared on Mnemosyne run start and
-- confirmed run end; type BOONS to re-sync if needed.
mnemApostatic = true
