--[[mudlet
type: trigger
name: DAEGGER SUMMONED
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes A-J
- Apostate
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
- pattern: Your daegger comes racing towards you, stopping unnaturally quickly to land in your grasp.
  type: 3
- pattern: ^Pointing your blood slick daegger at (\w+), you slash a pentagram in the air which ignites in crimson flame.$
  type: 1
- pattern: ^You start to wield a crimson-hued daegger in your (left|right) hand.$
  type: 1
]]--

daeggerhere = true

daeggerhunt = false