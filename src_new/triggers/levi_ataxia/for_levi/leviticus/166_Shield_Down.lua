--[[mudlet
type: trigger
name: Shield Down
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- MONK 1
- Monk
- Shikudo Triggers
- Shikudo
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
- pattern: ^The end of your staff smashes the magical shield surrounding (\w+) in an explosion of translucent shards\.$
  type: 1
- pattern: ^Bracing your feet, you drive .+ towards
  type: 1
]]--
-- v4.7.420: the SHATTER strike line ("Bracing your feet, you drive a twisted oaken staff towards
-- Claes.", attacker log :1109) is matched up to the word after the staff, so any staff matches. The
-- pattern named one, and staves differ: another monk wields "a dark ash wood staff" (defender log
-- :136).

-- PvP only: the fragment also matches a shatter at a denizen ("towards a black bear."), which the
-- old one-word pattern did not, and the basher's shatter rounds (basher/002) would clear the PvP
-- target's shield. PvE as the basher's triggers 337/338 tell it: a numeric target, or the basher on.
if type(target) ~= "string" or (ataxiaBasher and ataxiaBasher.enabled) then return end

targshield = false
erAff("shield")