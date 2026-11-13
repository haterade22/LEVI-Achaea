--[[mudlet
type: trigger
name: Artefact Power List Header
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
- pattern: ^Item ID\s+Item Name\s+Power\s+Level\s*$
  type: 1
]]--

-- ARTEFACT POWER LIST OWNED, its header row (the user, 2026-11-13). It opens the short window in
-- which 803 reads the item rows (misc_scripts/033).
if ataxia_artefactHeader then ataxia_artefactHeader() end
