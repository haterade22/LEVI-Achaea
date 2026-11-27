--[[mudlet
type: trigger
name: Hellfumes Cast
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- Mage
- Magi Offense Tracking
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
mFgColor: ''
mBgColor: ''
mSoundFile: ''
colorTriggerFgColor: ''
colorTriggerBgColor: ''
patterns:
- pattern: ^You coax an absolutely foul-smelling cloud of air from the bowels of the earth\.
  type: 1
]]--

-- Stamped on the game's cast line (captured 2026-11-27, kb/raw/live/hellfumes_evocation_2026-11-27.txt).
-- basher/002 ataxiaBasher_magiHellfumes holds 10 s when this is newer than the proc stamp.
ataxiaTemp = ataxiaTemp or {}
ataxiaTemp.hellfumesCastAt = getEpoch()
