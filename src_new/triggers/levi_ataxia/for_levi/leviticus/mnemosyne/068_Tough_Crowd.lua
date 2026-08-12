--[[mudlet
type: trigger
name: Tough Crowd
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
- pattern: ^Tough Crowd\s+\d+\s+\w+
  type: 1
]]--

-- BOONS row (Jester). BADJOKE now deals psychic damage to every denizen -- but stuns and stupefies US, so it is crowd-gated, cooldown-limited and refused while escaping or hurt.
--
-- Handled in ataxiaBasher_jesterBashing (basher/002). Cleared on Mnemosyne run start and
-- confirmed run end; type BOONS to re-sync if needed.
mnemToughCrowd = true
