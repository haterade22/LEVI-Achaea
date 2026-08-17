--[[mudlet
type: trigger
name: Shin Augment Ready
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Highlighting
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
mFgColor: '#ff0000'
mBgColor: '#ffff00'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
packageName: ''
patterns:
- pattern: ^You may augment yourself with shin energy once again\.$
  type: 1
]]--
-- THE COOLDOWN IS OVER, and the game volunteers it (captured live 2026-08-12). This removes the
-- last piece of arithmetic from the augment cycle: v4.7.270 measured the duration and then waited
-- that long, because "cooldown equal to the duration it was up for" was all we had. Now the end of
-- the cooldown is an event, so we wait for it instead of predicting it.
--
-- The measured wait is kept as a BACKSTOP, not the primary: a missed line would otherwise hold the
-- augment off for the rest of the run, which is the failure mode this codebase keeps writing down
-- (an optimistic flag cleared only by a confirmation becomes a livelock the moment the confirmation
-- cannot arrive). Whichever comes first releases it.
--
-- The same capture measured the cycle for the first time: dissipated at 10:25:09.886, ready at
-- 10:25:12.886 -- a THREE SECOND cooldown, so the augment before it had lasted three seconds. And
-- 10:25:15.257 (focus inward) to 10:25:18.916 (cover starts) is 3.66s, which corroborates the
-- stated 4s activation.
if ataxiaBasher_bmAugmentReady then ataxiaBasher_bmAugmentReady() end

selectString(line, 1)
fg("spring_green")
deselect()
resetFormat()
