--[[mudlet
type: trigger
name: Kata Gone
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- MONK 1
- Monk
- Shikudo Triggers
- Shikudo
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
- pattern: ^You can no longer maintain your deadly kata\.$
  type: 1
]]--

selectCurrentLine() fg("black") bg("old_lace")
katachain = 0
-- The chain lapsed (about 17-20 s after the last strike, vNTjvghY:5967); the form is kept. The
-- offenses read ataxia.vitals.kata, and Kata "is absent from charstats until a chain starts"
-- (basher/002), so charstats may never report the 0: zero it here. ataxia_kataAtRisk (monk/004)
-- reads that 0. The stumble recorder (monk/003) reads the time instead: a lapsed chain has nothing
-- left to stumble from. ataxiaTemp is never saved.
ataxia.vitals.kata = 0
ataxiaTemp.kataLapseAt = getEpoch()