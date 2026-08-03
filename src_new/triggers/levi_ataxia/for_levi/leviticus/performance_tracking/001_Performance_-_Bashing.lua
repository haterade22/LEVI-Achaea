--[[mudlet
type: trigger
name: Performance - Bashing
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes A-J
- Bard
- Bard Rework
- Performance Tracking
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
- pattern: ^Your grand performance shall last another (?<amount>.+) minutes\.$
  type: 1
]]--

-- This line is also the ANSWER to the per-ripple PERFORMANCE probe (explorer
-- M._bardPerformanceCheck): seeing it at all proves a performance is up, so clear the probe
-- stamp. If nothing clears it, the probe's timer recomposes.
bardperformance = true
if ataxiaTemp then ataxiaTemp.bardPerfProbe = nil end

bardperformancetimeleft = tonumber(matches.amount)