--[[mudlet
type: trigger
name: Foresight Cast
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Class Stuff
- Psion
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
- pattern: You direct your formidable mental might towards the task of piercing
  type: 2
]]--

-- "You direct your formidable mental might towards the task of piercing the very fabric of time
-- itself, seeking out a situation in the near future where a halfling semi-soldier will act as you
-- predict." (the user's log, 2026-09-25)
--
-- The line is ~160 characters and the server wraps it, so this matches the start of the first row.
-- Our foresight went out: its ~30s cooldown starts now (v4.7.359). Stamped HERE rather than when
-- the round is built, because a rebuilt round replaces the queued one -- see basher/002.
if ataxiaBasher_psionForesightCast then ataxiaBasher_psionForesightCast() end
