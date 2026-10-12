--[[mudlet
type: trigger
name: Reset Failsafe
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Class Stuff
- Monk
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
- pattern: ^A kata of at least \d+ must be performed
  type: 1
]]--

-- v4.7.417: a refused transition KEEPS the kata chain (log 2026-10-11: kata 3, refused, still 3, then 6
-- after the next combo). This used to zero our count, which then disagreed with the game until charstats
-- re-reported it. Now it only says the transition was refused.
cecho("\n   <red>-= transition refused: kata below 5 (the chain is kept) =-")