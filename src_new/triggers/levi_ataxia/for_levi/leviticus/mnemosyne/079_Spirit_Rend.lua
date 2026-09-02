--[[mudlet
type: trigger
name: Mnemosyne Spirit Rend
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
- pattern: ^Spirit Rend\s+\d+\s+\w+
  type: 1
]]--

-- A row in the BOONS list (name / echoes / rarity) confirms Spirit Rend is active: KAI ENFEEBLE
-- costs no kai, may target denizens, and HALVES the target's current health, once every 60
-- seconds. The Shikudo basher fires it in Rain form above `ataxiaBasher.spiritRendAt` (50%)
-- health (`ataxiaBasher_spiritRend`, basher/002). Cleared on Mnemosyne run start/end, like every
-- other boon flag. Type BOONS to re-sync if needed.
mnemSpiritRend = true
