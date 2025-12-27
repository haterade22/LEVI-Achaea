--[[mudlet
type: trigger
name: Applied
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- INFERNAL
- Fractures
- Decrease Fracture Count
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
- pattern: ^(\w+) takes some elixir from (.+?) and rubs it into (\w+) (legs|arms|torso|head).$
  type: 1
]]--

if isTargeted(matches[2]) then
  if matches[5] == "legs" then
    twohanded_decreaseFracture("torntendons")
   
  elseif matches[5] == "arms" then
    twohanded_decreaseFracture("wristfractures")
  elseif matches[5] == "head" then
    twohanded_decreaseFracture("skullfractures")
  elseif matches[5] == "torso" then
    twohanded_decreaseFracture("crackedribs")
  end
  flyu = matches[5]
end

 