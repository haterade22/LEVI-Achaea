--[[mudlet
type: trigger
name: Armour Probe Header
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
- pattern: ^This armour has (\d+) embrasures?\.$
  type: 1
]]--

-- "This armour has 3 embrasures." opens a `probe armour` block (v4.7.323). It starts the snapshot
-- the embrasure lines (002) fill, and records the armour's capacity, so a slot the probe does not
-- list reads as EMPTY rather than as whatever we believed before.
if ataxia and ataxia.armour and ataxia.armour.onProbeHeader then
  ataxia.armour.onProbeHeader(matches[2])
end
