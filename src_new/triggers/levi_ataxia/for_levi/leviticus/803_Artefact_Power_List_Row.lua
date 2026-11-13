--[[mudlet
type: trigger
name: Artefact Power List Row
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
- pattern: ^\s*\d+\s+\S.*\s[a-z_]+\s+(?:\d+|-)\s*$
  type: 1
]]--

-- ARTEFACT POWER LIST OWNED, one item row: "385702  an Aldar Diadem  faster_eq  2". Read only inside
-- the window 802's header opens, so a line of numbers in other output is never taken for an artefact
-- (misc_scripts/033).
if ataxia_artefactRow then ataxia_artefactRow(line) end
