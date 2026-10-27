--[[mudlet
type: trigger
name: Trait List Racial
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
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
- pattern: ^Racial:\s+(.+?)\s*$
  type: 1
]]--

-- TRAIT LIST KNOWN, its first row: "Racial:   Child of Ceylon" (the user, 2026-10-27). It starts
-- a fresh list and opens the short window in which 793 reads the Level rows (misc_scripts/031).
if ataxia_traitRacial then ataxia_traitRacial(matches[2]) end
