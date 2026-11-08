--[[mudlet
type: trigger
name: Goldenseal (Mycalium)
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Remove Afflictions
- Herbs
attributes:
  isActive: 'yes'
  isFolder: 'no'
  isTempTrigger: 'no'
  isMultiline: 'yes'
  isPerlSlashGOption: 'no'
  isColorizerTrigger: 'no'
  isFilterTrigger: 'no'
  isSoundTrigger: 'no'
  isColorTrigger: 'no'
  isColorTriggerFg: 'no'
  isColorTriggerBg: 'no'
triggerType: 0
conditonLineDelta: 1
mStayOpen: 0
mCommand: ''
packageName: ''
mFgColor: '#ff0000'
mBgColor: '#ffff00'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
patterns:
- pattern: ^(\w+) eats a (goldenseal root|plumbum flake).$
  type: 1
- pattern: ^(\w+) ceases \w+ violent trembling.$
  type: 1
]]--

-- Known-line goldenseal cure: the eat followed by "ceases <his/her> violent
-- trembling" means the eat cured MYCALIUM. The eat line itself is handled by
-- 002_Goldenseal_(Madness) (V3 cure, plant balance), so this only records
-- the known cure. (v4.7.372, deep review: the second pattern was type 0 --
-- SUBSTRING -- so its regex never matched; and the body re-ran the whole eat
-- handling, a third V3 cure per eat, then erAff'd mycalium for ANY target.)
-- 002 still charged the eat as a random goldenseal cure on its own line, so this erase made one
-- eat take two afflictions. ataxia_knownCureV3 puts 002's branches back first, and the eat counts
-- once, as mycalium (2026-11-08 deep review, F14). Both lines must name the same person.
local who = multimatches[2] and multimatches[2][2]
if who and who == multimatches[1][2] and isTargeted(who) then
	if ataxia_knownCureV3 then ataxia_knownCureV3("goldenseal", who, "mycalium") end
	erAff("mycalium")
end