--[[mudlet
type: trigger
name: Add Limb Damage - Spear - Head & Torso
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
- pattern: ^(\w+) viciously lacerates your (\w+) with (.+)\.$
  type: 1
- pattern: '1'
  type: 5
- pattern: ^The attack rebounds back onto \w+\.$
  type: 1
]]--

if matches[2] == target then
  if matches[3] == "head" then
    lb[target].hits["head"] = lb[target].hits["head"] + 15
  elseif matches[3] == "torso" then
    lb[target].hits["torso"] = lb[target].hits["torso"] + 15
  
  end
end