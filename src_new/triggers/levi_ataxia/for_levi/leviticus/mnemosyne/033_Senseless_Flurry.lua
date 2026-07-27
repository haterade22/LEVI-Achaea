--[[mudlet
type: trigger
name: Mnemosyne Senseless Flurry
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
- pattern: ^Senseless Flurry\s+\d+\s+\w+
  type: 1
]]--

-- A row in the BOONS list (name / echoes / rarity) confirms Senseless Flurry is
-- active: balance recovers 30% faster while the numbness defence is up. The
-- Shikudo basher keeps NUMB up in Rain form (eq rider alongside the combo;
-- Kai Choke outranks it -- ataxiaBasher_senselessFlurryNumb, basher/002).
-- Cleared on Mnemosyne run start/end (mirrors the other boon flags). Type
-- BOONS to re-sync if needed.
mnemSenselessFlurry = true
