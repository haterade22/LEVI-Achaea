--[[mudlet
type: trigger
name: Powderise
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Affs Post Queue - Gated
- Classes A-J
- Earth Lord
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
- pattern: ^Your magma-wreathed fist smashes into the (head|torso|right leg|left leg|left arm|right arm) of (\w+).$
  type: 1
- pattern: ^Your fist crunches into the (head|torso|right leg|left leg|left arm|right arm) of (\w+).$
  type: 1
- pattern: ^Your fist smashes into the (head|torso|right leg|left leg|left arm|right arm) of (\w+).$
  type: 1
- pattern: ^Bones crackle and pop as your fist smashes into the (head|torso|right leg|left leg|left arm|right arm) of (\w+)
    with pulverising force.$
  type: 1
]]--

if isTargeted(matches[3]) then
  earth_powderiseHit(matches[2])
  
  targetIshere = true
end