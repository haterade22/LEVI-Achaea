--[[mudlet
type: trigger
name: Performance Ended
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
- pattern: Your performance fades away into silence.
  type: 3
]]--

-- "Your performance fades away into silence." -- the AUTHORITATIVE end of the performance,
-- and therefore the right moment to put a new one up (user, 2026-08-03: "we should've put it
-- back up based on the performance").
--
-- Until v4.7.203 the recompose was driven by a 15-minute timer plus the "you are not in fact
-- performing" ERROR (trigger 005). A timer cannot stay in step with the real thing: the live
-- log shows it firing while the song was still running ("You are already performing,
-- wordsmith."), wasting the compose -- and then the performance ended moments later with
-- nothing to replace it, leaving the bard performing NOTHING until some later command errored
-- and trigger 005 finally noticed.
--
-- This is the package's own rule, applied late: prefer the game's own line to a guess about
-- timing. The 15-minute timer stays as a backstop for a fade line we somehow miss; trigger
-- 005 stays as the last-resort catch.
bardperformance = false
if gmcp.Char.Status.class == "Bard" and ataxiaBasher and ataxiaBasher.enabled and ataxiaBasher_bardCompose then
	ataxiaBasher_bardCompose()
end