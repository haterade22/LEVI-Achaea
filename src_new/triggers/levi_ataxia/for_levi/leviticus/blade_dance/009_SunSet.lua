--[[mudlet
type: trigger
name: SunSet
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes A-J
- Bard
- Bard Rework
- Blade Dance
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
- pattern: ^Blood erupts from the (\w+) arm of \w+ in a crimson spray\.$
  type: 1
]]--

if matches[2] == "right" then
tarAffed("damagedhead")
tarAffed("damagedrightarm")
tarAffed("impatience")
tarAffed("stupidity")
tarAffed("slickness")
lb[target].hits["right arm"] = lb[target].hits["right arm"] + rapierdamage
lb[target].hits["head"] = lb[target].hits["head"] + rapierdamage
elseif matches[2] == "left" then
tarAffed("damagedhead")
tarAffed("damagedleftarm")
tarAffed("impatience")
tarAffed("stupidity")
tarAffed("slickness")
lb[target].hits["left arm"] = lb[target].hits["left arm"] + rapierdamage
lb[target].hits["head"] = lb[target].hits["head"] + rapierdamage
end
bardsunset = true
tempTimer(2.5, [[bardsunset = false]])