--[[mudlet
type: trigger
name: Corpse Eaten
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
packageName: ''
mFgColor: '#ff0000'
mBgColor: '#ffff00'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
patterns:
- pattern: you dig into the corpse of
  type: 0
- pattern: Your fatigue fades away as the meat slides down your gullet.
  type: 0
]]--

-- OBLIGATE CARNIVORE -- the corpse actually went down. Captured live 2026-09-02:
--
--   "With primal ferocity, you dig into the corpse of a haskrovska vine, sating your appetite
--    with the creature's flesh."
--   "Your fatigue fades away as the meat slides down your gullet."
--
-- TWO PATTERNS, TWO JOBS. The first sentence runs to about 120 characters, so Achaea's
-- server-side wrap at the player's WIDTH can hand Mudlet two physical lines (v4.7.286) -- the
-- fragment used is therefore short and sits EARLY, where a break is least likely to fall through
-- it. The second line is the endurance/willpower half of the same mouthful and is matched in its
-- own right, so the restore is visible even if the wrap swallows the first.
--
-- SUBSTRING patterns rather than anchored regex: both fragments are mid-line by construction, so
-- `^`/`$` could not be used even if we wanted them, and neither phrase occurs anywhere else.
--
-- `medium_sea_green` is DELIBERATELY SHARED with the inhibit and cleanse lines rather than given
-- a colour of its own -- same meaning class, restoration, which is the convention the Human Spirit
-- proc already follows (v4.7.286). A new colour per line is how a palette stops meaning anything.
--
-- It also CONFIRMS the eat, re-stamping the throttle from the line that proves food went down
-- instead of only from the attempt -- an `ii corpse` probe that found nothing has spent nothing.
-- Self-proving, so it re-latches the flag: this text only prints with the boon up, and a missed
-- BOONS row therefore cannot leave us believing we cannot eat.
selectString(line, 1)
fg("medium_sea_green")
setBold(true)
deselect()
resetFormat()

if ataxia_carnivoreAte then ataxia_carnivoreAte() end
