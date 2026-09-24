--[[mudlet
type: trigger
name: Belch Highlight
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
- pattern: ^You belch a cloud of stinking gas out of your lungs and into your surroundings\.$
  type: 1
- pattern: ^Your rotten breath befouls the air, plaguing all who stand before you with choking filth\.$
  type: 1
]]--

-- DEAD BREATH fired (v4.7.340, user: "highlight the belch and soulstorm a specific color ... so I
-- can confirm working"). Both halves are coloured: the first line is the belch itself, the second
-- is the boon's own AoE -- seeing the pair is the confirmation that the RIDER ran and the BOON is
-- up, which is exactly the question being asked.
--
-- Highlight only. The state these lines drive lives in `778_Belch_Landed` (basher/014), and a
-- second trigger stamping the same thing would be two owners for one fact.
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
