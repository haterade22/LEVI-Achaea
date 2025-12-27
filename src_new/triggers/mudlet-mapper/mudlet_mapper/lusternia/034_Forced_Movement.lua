--[[mudlet
type: trigger
name: Forced Movement
hierarchy:
- mudlet-mapper
- Mudlet Mapper
- Lusternia
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
- pattern: The soft ground around you suddenly gives way and you find yourself sliding down a muddy embankment, ending up
    in an undignified heap on the floor of a dark chamber.
  type: 3
]]--

if mmp.autowalking then
  mmp.hasty = true
  mmp.setmovetimer(0.5)
end