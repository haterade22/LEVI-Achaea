--[[mudlet
type: trigger
name: Kelp (Unknown)
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
  isMultiline: 'no'
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
- pattern: ^(\w+) eats (a withered piece of kelp|a piece of kelp|an aurum flake).$
  type: 1
]]--


if matches[2] == target then
    if anorexiaFailsafe then
        tAffs[lastFocus] = true
        ataxiaEcho("Backtracked anorexia being cured with last focus.")
        anorexiaFailsafe = nil
        lastFocus = nil
    end
-- The eat is charged now as a random cure. When the next line names the cure ("The skin of X ceases
-- secreting slime." -> rebbies, third-person_removes/002), that trigger puts the branches back and
-- charges the named one alone (ataxia_knownCureV3, ataxia/001), so one eat takes one affliction.
-- Mercury goes BEFORE the random cure, as in 002_Goldenseal: an erase between it and the known-cure
-- line makes the comparison of the branches miss. Mercury is in no cure table, so the random cure
-- weighs the same afflictions either way.
local hadMercury = tAffs.mercury
if hadMercury then erAff("mercury") end
if ataxia_randomCureV3 then
    ataxia_randomCureV3("kelp", matches[2], function() targetAteWrapper("kelp") end)
else
    targetAteWrapper("kelp")
end
-- Track for adaptive serpent offense (ekstatus's kelp count), as 007_Ginseng does for ginseng
if serpent and serpent.trackCure then serpent.trackCure("kelp") end
if passiveFailsafe then restorePassiveCure() end
    tBals.plant = false
  if tBals.timers.plant then killTimer(tBals.timers.plant) end
    if hadMercury then
        tBals.timers.plant = tempTimer(1.9, [[tBals.plant = true; tBals.timers.plant = nil]])
    else
        tBals.timers.plant = tempTimer(1.3, [[tBals.plant = true; tBals.timers.plant = nil]])
    end
    targetIshere = true
end

selectString(line, 1)
fg("DarkViolet")
resetFormat()