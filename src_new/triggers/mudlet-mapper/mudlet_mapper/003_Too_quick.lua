--[[mudlet
type: trigger
name: Too quick
hierarchy:
- mudlet-mapper
- Mudlet Mapper
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
conditonLineDelta: 99
mStayOpen: 0
mCommand: ''
packageName: ''
mFgColor: '#ff0000'
mBgColor: '#ffff00'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
patterns:
- pattern: Now now, don't be so hasty!
  type: 3
- pattern: You can not move that fast!
  type: 3
- pattern: You cannot move that fast, slow down!
  type: 3
]]--

if mmp.autowalking then
  mmp.hasty = true
  mmp.setmovetimer(0.5)
  mmp.deleteLineP()
end