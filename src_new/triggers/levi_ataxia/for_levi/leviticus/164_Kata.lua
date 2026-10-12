--[[mudlet
type: trigger
name: Kata
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
- pattern: ^You are now maintaining a kata chain of (\d+) actions\.$
  type: 1
]]--

selectCurrentLine() fg("black") bg("old_lace")
katachain = tonumber(matches[2])
-- The offenses read ataxia.vitals.kata. This line prints at the end of each combo, before the
-- prompt, so it is fresher than charstats, which lags a tick (basher/002). kataLast and kataAt
-- feed monk/004 (ataxia_kataAtRisk) and the stumble recorder (monk/003); ataxiaTemp is never saved.
ataxia.vitals.kata = katachain
ataxiaTemp.kataLast = katachain
ataxiaTemp.kataAt = getEpoch()