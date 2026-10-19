--[[mudlet
type: trigger
name: Assess
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- Mage
- General
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
- pattern: ^You glance over (\w+) and see that (\w+) health is at (\d{1,5})\/(\d{1,6})
  type: 1
]]--

-- Only our target's health (v4.7.429). Any "You glance over X" line set it, whoever X was, and P1
-- (destroy) and P4 (stormhammer) in mage/004 read it: one look at a bystander put their health on
-- our target. 698_Assess makes the same check.
if not isTargeted(matches[2]) then return end
targetHealth = math.floor((matches[4] / matches[5]) * 100)