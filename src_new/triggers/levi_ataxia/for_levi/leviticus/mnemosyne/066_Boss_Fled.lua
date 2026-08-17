--[[mudlet
type: trigger
name: Boss Fled
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Mnemosyne
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
- pattern: \b(?:out to the|departs?(?: to the)?)\s+(north|northeast|east|southeast|south|southwest|west|northwest|up|down)\b
  type: 1
]]--

-- The departure half. TWO GRAMMARS, both captured live:
--
--   His fingers plucking a plaintive melody on his lyre, a satyri bard strolls OUT TO THE
--   southeast, the sorrowful music gradually fading in his wake.          (Lyaeus, 2026-08-11)
--
--   The muted rustling of fabric accompanies Celepharn as he DEPARTS east. (Celepharn, 2026-08-17)
--
-- v4.7.255 built this on "out to the <direction>" as the fragment every denizen shares. It is
-- not: the second boss uses a different SYNTACTIC FRAME entirely, so the panic line fired, the
-- departure never matched, and the pair never completed -- the boss walked and the chase that
-- exists precisely for that never ran. `departs` (and `depart`, and an optional "to the") is the
-- second frame.
--
-- MATCHED ON THE DIRECTION FRAGMENT, NOT THE WHOLE SENTENCE, and deliberately so. Every
-- denizen words its exit differently -- "strolls out to", "prowls out to", "stomps out to"
-- (see the PvP set in trigger 637) -- and enumerating the VERBS is how you end up with a trigger
-- that works for one boss and silently misses the next. The DIRECTIONS are enumerated instead, so
-- the pattern cannot match arbitrary prose.
--
-- WIDENING OBLIGES SAYING WHAT IT STILL REFUSES (v4.7.262). `departs <dir>` is a far commoner
-- English frame than `out to the <dir>` -- ordinary movement lines use it -- so the whole line is
-- now passed through as corroborating evidence. It can only STRENGTHEN, never veto: Lyaeus's
-- departure names no one ("a satyri bard"), so a line that does not carry the boss's name proves
-- nothing and must still be followed. What it buys is an honest log -- whether we identified the
-- runner by NAME or merely inferred it from the panic window.
--
-- The breadth is safe because this decides nothing on its own: M.onDenizenFled follows only when
-- a matching boss panicked within the last few seconds (trigger 065), the basher is on, we are
-- in the tower, and we are not escaping, recovering, standing in lava or below the escape
-- threshold. An ordinary denizen wandering off costs one table lookup here.
if ataxia and ataxia.mnemosyne and ataxia.mnemosyne.onDenizenFled then
	ataxia.mnemosyne.onDenizenFled(matches[2], line)
end
