--[[mudlet
type: trigger
name: Gravehands Highlight
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
- pattern: hands of rotting flesh and white bone push out of the ground
  type: 0
- pattern: the chill of the grave striking out amidst a rasping chorus of death
  type: 0
]]--

-- ARMY OF THE DEAD fired (v4.7.347). Both halves are coloured, and the pair is the confirmation:
--
--   You mutter words of death and decay, and suddenly the ground breaks open all around as
--   hands of rotting flesh and white bone push out of the ground.          <- the summon
--   Putrescent flesh and rotting dermis grasp in vain at all present, the chill of the grave
--   striking out amidst a rasping chorus of death.                         <- the boon's damage
--
-- The second line is the one that proves the BOON rather than the ability, which is exactly what
-- the user asked to be able to see at a glance for the other two riders ("so I can confirm
-- working"). Seeing the first without the second means the hands went up and the boon did not.
--
-- Highlight only. The state lives in `782_Gravehands_Up` (basher/002); a second trigger stamping
-- the same fact would be two owners for one thing.
--
-- `cadet_blue` bold -- the third necromancy rider, and the third colour (v4.7.347). The belch is
-- goldenrod and the soulstorm medium_orchid; a shared colour is what v4.7.344 was raised to fix,
-- so this one takes the palette's grave-chill blue. It avoids every name that already means
-- something: chartreuse is "an attack LANDED", red is damage, dark_violet is the `rare` rarity,
-- and the whole orange family is held in reserve.
selectString(line, 1)
fg("cadet_blue")
setBold(true)
deselect()
resetFormat()
