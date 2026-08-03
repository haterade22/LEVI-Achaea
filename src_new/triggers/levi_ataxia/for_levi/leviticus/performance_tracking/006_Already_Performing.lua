--[[mudlet
type: trigger
name: Already Performing
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
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
- pattern: ^You are already performing
  type: 2
]]--

-- "You are already performing, wordsmith." -- the REFUSAL half of the compose cycle, and the
-- proof that a recompose fired too early (user's live log, 2026-08-03: "I think this happened
-- too soon").
--
-- Every timer-free ability in this package wants a fire line to confirm and a refusal line to
-- cancel; the bash compose had neither, only a 15-minute guess. The fade line (trigger 002)
-- is the confirm half. This is the cancel half, and it carries real information: the song is
-- STILL UP, so the state we just doubted is actually fine.
--
-- So: re-assert `bardperformance`, and push the backstop timer out rather than letting it
-- retry immediately. Without that the timer stays out of phase with the real performance and
-- re-fires the moment it comes round again -- the exact loop the log caught.
--
-- Type 2 (begin-of-line substring), not 3: the line ends "..., wordsmith." with a vocative
-- that may vary by title, and an exact whole-line match would silently never fire.
bardperformance = true
if bardComposePending ~= nil then bardComposePending = false end
if enableTimer then enableTimer("Bard Performance") end -- re-arm the 15-min backstop from NOW
