--[[mudlet
type: trigger
name: Transcendence Set
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
- pattern: '^Your body and mind continue to harmonise\: you are (\d+) percent'
  type: 1
- pattern: '^Your inaction causes the harmonisation of your body and mind to falter\: you are now only (\d+) percent'
  type: 1
]]--

-- THE DECAY PATTERN NEVER FIRED (v4.7.349, user pasting the whole ladder 60 -> 50 -> ... -> 10).
--
-- Both patterns used to run to a `$` anchor, and the decay line is 128 characters long. Achaea
-- wraps server-side, so it arrives as TWO lines -- the user's paste breaks after "of the way to"
-- at column 114, identically on all six -- and an anchored pattern can never match a line that is
-- only ever delivered in halves. The build line is 94 characters, fits, and matched fine, which
-- is exactly what made this invisible: transcendence counted UP correctly and simply never
-- counted back down.
--
-- The cost was not cosmetic. `ataxiaBasher_psionBashing` sends `psi shatter <target>` when it
-- believes transcendence is 100, so a value that could rise but never fall meant the round kept
-- spending on a shatter the game had long since taken away.
--
-- Both patterns now stop at the captured number, well before any wrap, and keep only the `^`
-- anchor -- the opening words are distinctive enough that nothing else can match them. The rule
-- this keeps relearning: an anchored pattern is a bet that the line is short enough, and the
-- lines that break it are exactly the informative ones (v4.7.286, the soulstorm landing).
ataxiaTemp.transcendence = tonumber(matches[2])
-- The decay line wraps, so its tail arrives as a line of its own; psion/004 gags it, but only
-- straight after one of these (v4.7.351, deep review).
ataxiaTemp.transcendLineAt = (getEpoch and getEpoch()) or os.time()
if ataxiaBasher.enabled and not ataxiaBasher.manual then
	deleteFull()
end