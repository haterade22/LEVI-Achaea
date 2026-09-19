--[[mudlet
type: trigger
name: Armour Probe
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- Gear System
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
- pattern: ^(\d+): .+ \((paragon\d+)\)
  type: 1
- pattern: ^(\d+): Empty\.
  type: 1
]]--

-- One embrasure line of `probe armour`:
--   1: an auspicious icosagon paragon (paragon361796)     critical level increase chance
--   3: Empty.
-- Classified by ataxia.armour.onProbeLine (v4.7.323), which reads only probes the armour module
-- sent itself and builds a snapshot the header (003) opened.
if ataxia and ataxia.armour and ataxia.armour.onProbeLine then
  ataxia.armour.onProbeLine(line)
end
