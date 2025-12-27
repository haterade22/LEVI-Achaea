--[[mudlet
type: trigger
name: limb salve
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- limb.1.2
- Limb
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
- pattern: ^(\w+) takes some salve from a vial and rubs it on \w+ (.+).$
  type: 1
]]--

if target == matches[2] then

if lb[matches[2]] then 
  -- Add your own highlights here!
  lb.salve(matches[2], matches[3])
end

end