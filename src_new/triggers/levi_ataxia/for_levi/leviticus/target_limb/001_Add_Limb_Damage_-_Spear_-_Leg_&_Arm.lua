--[[mudlet
type: trigger
name: Add Limb Damage - Spear - Leg & Arm
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- Target Limb
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
- pattern: ^(\w+) viciously lacerates your (\w+) (\w+) with (.+)\.$
  type: 1
- pattern: '1'
  type: 5
- pattern: ^The attack rebounds back onto \w+\.$
  type: 1
]]--

if matches[2] == target then
  if matches[3] == "left" and matches[4] == "leg" then
    lb[target].hits["left leg"] = lb[target].hits["left leg"] + 15
  elseif matches[3] == "right" and matches[4] == "leg" then
    lb[target].hits["right leg"] = lb[target].hits["right leg"] + 15
  elseif matches[3] == "left" and matches[4] == "arm" then
    lb[target].hits["left arm"] = lb[target].hits["left arm"] + 15
  elseif matches[3] == "right" and matches[4] == "arm" then
    lb[target].hits["right arm"] = lb[target].hits["right arm"] + 15
  end
end