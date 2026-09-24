--[[mudlet
type: trigger
name: Soulstorm Highlight
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
- pattern: ^You call forth an unholy tide of necromantic essence and release it, engulfing .+ in a profane soulstorm\.$
  type: 1
- pattern: form withers as the necromantic storm eats away at
  type: 0
]]--

-- DEATHTEMPEST's SOULSTORM fired (v4.7.340, same request). Two lines again: the cast, and the
-- profane landing on the denizen ("An acolyte of Life's form withers as the necromantic storm eats
-- away at his lifeforce, draining him.").
--
-- The second is a SUBSTRING, and the mob's name is why: it opens the line, is of arbitrary length,
-- and Achaea wraps server-side -- the same reason the Kai Choke landing beside this one is matched
-- on fragments rather than anchored (v4.7.286). The fragment starts well clear of the name and
-- stops before the trailing pronoun, which varies with the denizen's gender.
--
-- Highlight only; `780_Soulstorm_Landed` owns the once-per-denizen bookkeeping.
--
-- `goldenrod` bold -- the amber the user asked for ("orange or a like colour"). NOT `orange`
-- itself: `tools/check_colours.py` holds the whole orange family in reserve, and goldenrod is the
-- palette's amber that this package already uses for a loud-but-not-alarming state (the starving
-- box echo). Distinct from `chartreuse`, which means "an attack LANDED on the target", because
-- these two lines mean "the boon-driven rider fired at all" -- which is what is being confirmed.
selectString(line, 1)
fg("goldenrod")
setBold(true)
deselect()
resetFormat()
