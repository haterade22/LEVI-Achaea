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
-- `medium_orchid` bold (v4.7.344, user: "make this a different colour highlight please"). The two
-- riders were both goldenrod, which made them one indistinguishable amber block in a busy room --
-- and the whole point of colouring them was telling them apart at a glance. The belch keeps the
-- amber; the soulstorm takes the violet, which is this palette's magical/necromantic family
-- (`medium_orchid` is the Magical resistance colour on the bonuses panel) and is as far from
-- goldenrod as the palette gets without stealing a colour that already means something:
-- `chartreuse` is "an attack landed", red is damage, `dark_violet` is the `rare` rarity.
selectString(line, 1)
fg("medium_orchid")
setBold(true)
deselect()
resetFormat()
