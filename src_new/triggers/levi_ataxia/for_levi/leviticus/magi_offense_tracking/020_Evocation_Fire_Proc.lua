--[[mudlet
type: trigger
name: Evocation of Fire Proc
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
- pattern: ^Elemental Fire manifests in a searing plume of Kkractle's wrath
  type: 1
]]--

-- The Evocation of Fire boon fired (once per 30 s): stamp its clock on the game's line.
-- Read by basher/002 ataxiaBasher_magiHellfumes.
ataxiaTemp = ataxiaTemp or {}
ataxiaTemp.evocationFireAt = getEpoch()
