--[[mudlet
type: trigger
name: Sunrise
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
- pattern: ^The (\w+) leg of \w+ buckles beneath \w+, and \w+ goes sprawling\.$
  type: 1
]]--

if matches[2] == "left" then
tarAffed("damagedleftleg")
if applyAffV3 then applyAffV3("damagedleftleg") end
tarAffed("mildtrauma")
if applyAffV3 then applyAffV3("mildtrauma") end
tarAffed("prone")
if applyAffV3 then applyAffV3("prone") end
tarAffed("asthma")
if applyAffV3 then applyAffV3("asthma") end

lb[target].hits["left leg"] = lb[target].hits["left leg"] + rapierdamage
lb[target].hits["torso"] = lb[target].hits["torso"] + rapierdamage



elseif matches[2] == "right" then
tarAffed("damagedrightleg")
if applyAffV3 then applyAffV3("damagedrightleg") end
tarAffed("prone")
if applyAffV3 then applyAffV3("prone") end
tarAffed("asthma")
if applyAffV3 then applyAffV3("asthma") end
tarAffed("mildtrauma")
if applyAffV3 then applyAffV3("mildtrauma") end

lb[target].hits["right leg"] = lb[target].hits["right leg"] + rapierdamage
lb[target].hits["torso"] = lb[target].hits["torso"] + rapierdamage


end
bardsunrise = true
tempTimer(2.3, [[bardsunrise = false]])
