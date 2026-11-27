--[[mudlet
type: trigger
name: Quake Cast
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
- pattern: ^Calling upon Garash, you summon a quake to sunder the ground beneath your feet\.
  type: 1
]]--

-- Evocation of Earth clock: stamped on the game's cast line (user log 2026-11-27); no proc line is
-- captured. Read by basher/002 ataxiaBasher_magiQuake.
ataxiaTemp = ataxiaTemp or {}
ataxiaTemp.quakeCastAt = getEpoch()
