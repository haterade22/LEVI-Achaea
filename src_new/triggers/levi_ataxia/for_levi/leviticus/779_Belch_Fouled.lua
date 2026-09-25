--[[mudlet
type: trigger
name: Belch Fouled
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Basher
- Bashing
- Basher Lines
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
- pattern: ^You take in a deep breath in preparation for your belch, but cough and sputter
  type: 1
]]--

-- MATCHED EARLY, BECAUSE THE SERVER WRAPS (v4.7.351, deep review). This user's Achaea wraps
-- at 119-124 columns (measured from the break points in their pastes), and the full line is
-- longer than that. A pattern that runs past the break -- or a fragment that straddles it --
-- can never match, and this one did exactly that from the day it shipped.
--
-- 128 characters, anchored at both ends: the foul-room hold never engaged, so the belch was
-- re-sent into a room still full of its own gas every five seconds.

-- The refusal (live 2026-09-24): the room is still full of the gas we just laid, so another belch
-- is refused. Remembered PER ROOM and cleared by moving -- the next room's air is clean, and a
-- flat cooldown would either waste the equilibrium there or keep retrying here.
if ataxiaBasher_belchFouled then ataxiaBasher_belchFouled() end
