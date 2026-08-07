--[[mudlet
type: trigger
name: Gear Rage Threshold
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
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
- pattern: deal (\d+)% bonus damage so long as you have (\d+) battlerage or more
  type: 1
]]--

-- THE GAME TELLS US THE RAGE FLOOR (v4.7.231). From the gear TOTAL BONUSES summary:
--
--   "Your attacks will deal 23% bonus damage so long as you have 40 battlerage or more."
--
-- `bash floor 40` was always a manual restatement of this number, and a manual restatement
-- goes stale the moment the gear changes. Reading it from the game's own summary means the
-- floor is right by construction -- swap the chest and the floor follows.
--
-- SUBSTRING (type 0), not an anchored whole line: the summary line begins "Your attacks will
-- deal ..." but the same clause could reasonably be printed inside a GEAR PROBE for the single
-- item, with different lead-in text. Anchoring would silently miss that, and a trigger that
-- silently misses is the failure mode this project keeps re-learning (type 3 killed two
-- triggers outright). The clause itself is specific enough that a false positive is not a
-- realistic worry.
--
-- The work lives in gearAudit.applyRageThreshold (gear_system/001) so it is unit-testable;
-- this body only routes. Nil-guarded because triggers load independently of scripts.
if gearAudit and gearAudit.applyRageThreshold then
  gearAudit.applyRageThreshold(line)
end
