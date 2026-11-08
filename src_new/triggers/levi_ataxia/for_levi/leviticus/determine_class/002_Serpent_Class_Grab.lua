--[[mudlet
type: trigger
name: Serpent Class Grab
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Curing Stuff
- Priority Management
- Determine Class
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
- pattern: ^(\w+) quickly pricks you with \w+ dirk\.$
  type: 1
- pattern: ^Striking like a snake, (\w+) follows the first attack with another\.$
  type: 1
- pattern: ^(\w+) sinks \w+ fangs into your body and you wince in pain\.$
  type: 1
- pattern: ^(\w+) fixes \w+ gaze to yours and hisses a sharp command\.$
  type: 1
- pattern: ^(\w+) flays away your (?:shield|aura of rebounding) defence\.$
  type: 1
- pattern: ^(\w+) snaps \w+ fingers in front of you\.$
  type: 1
- pattern: ^(\w+) fixes you with an entrancing stare
  type: 1
]]--

-- A Serpent's lines aimed at us; matches[2] is the Serpent. Three patterns here matched no line in
-- any log ("sinks <his> fangs into you, injecting ... venom", "delivers a quick, stinging bite",
-- "whips <his> whip at you, ripping away your ..."), so a Serpent who opened with a flay or a
-- suggestion was detected only at the first prick: Kalys's flay at
-- kb/raw/logs/2026-11-01_elmer_shikudo-vs-serpent_noresult_g-lD00-h.txt:37, "Curing against
-- Serpent" after his prick at :60-61 (2026-11-08 review, F37). They are now the real lines:
--   Thato sinks her fangs into your body and you wince in pain.   (the impulse's bite,
--     2026-11-01_claes_runewarden-vs-serpent_loss_azbErKcK.txt:1242)
--   Thato fixes her gaze to yours and hisses a sharp command.     (the impulse, azbErKcK:1238)
--   Kalys flays away your shield defence.                         (g-lD00-h:37)
--   Thato flays away your aura of rebounding defence.             (azbErKcK:89)
--   Thato snaps her fingers in front of you.                      (the snap, azbErKcK:275)
-- Pariah's "Talo fixes his gaze to yours, raising his right hand, ..." is not the command line, and
-- the pet's "... sinks its fangs into your neck ..." names no Serpent; neither matches.
classDetect.setAttackerClass(matches[2], "Serpent")
