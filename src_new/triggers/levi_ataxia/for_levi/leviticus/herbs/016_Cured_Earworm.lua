--[[mudlet
type: trigger
name: Cured Earworm
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Remove Afflictions
- Herbs
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
- pattern: ^(\w+) gives a sigh of relief\.$
  type: 1
]]--

if matches[2] == target then
erAff("retribution")
-- The sigh follows a cuprum/bellwort eat that cured RETRIBUTION ("Archaeon eats a cuprum flake." then
-- "Archaeon gives a sigh of relief.", kb/raw/logs/2026-11-01_nikita_depthswalker-vs-serpent_win_X8pRorzR.txt:425-426).
-- Earworm is smoked (elm/cinnabar), so the earworm erase that stood here took a second affliction
-- for one cure (2026-11-08 deep review, F44; herbs/009 dropped the same erase in v4.7.372).
end