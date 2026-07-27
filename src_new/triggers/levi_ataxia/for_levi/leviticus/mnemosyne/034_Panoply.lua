--[[mudlet
type: trigger
name: Mnemosyne Panoply
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
- pattern: ^Panoply\s+\d+\s+\w+
  type: 1
]]--

-- A row in the BOONS list (name / echoes / rarity) confirms Panoply is active:
-- WEAVE FLURRY's damage scales with strikes landed, randomly dealing 60-200% per
-- attack. The Psion basher swaps its deathblow bash to flurry while this is up
-- (ataxiaBasher_psionBashing, basher/002). Cleared on Mnemosyne run start/end
-- (mirrors the other boon flags). Type BOONS to re-sync if needed.
psionPanoply = true
