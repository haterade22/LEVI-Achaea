--[[mudlet
type: trigger
name: LOCK GAG
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Misc Tracking
- Allies/Enemies
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
- pattern: You must cease your current lock attempt before trying another.
  type: 3
- pattern: ^You focus your mind, and begin to concentrate on forming a mind lock with (\w+).$
  type: 1
- pattern: ^You continue to delve deeper and deeper into the mind of (\w+).$
  type: 1
- pattern: You do not possess a mindlock.
  type: 3
]]--

mindlocked = false
-- "You do not possess a mindlock." stays on screen: the game is telling us we hold no lock, and
-- gagged, that looked like nothing at all. No log has it, so which command prints it is
-- unconfirmed (perhaps MIND UNLOCK). It is not how a MIND command that needs a lock is refused:
-- that is "You require a mindlock to perform that ability." (MIND PRINT and SAPIENCE,
-- kb/raw/logs/2026-10-11_mystor_shikudo-vs-apostate_win_LcJC-rJ5.txt:7-10), which no trigger
-- gags or reads, so it is the line the CONFLICTS #7 test (MIND BLACKOUT without a lock) will
-- most likely see. The lock-attempt lines are still noise.
if line ~= "You do not possess a mindlock." then
  deleteFull()
end
