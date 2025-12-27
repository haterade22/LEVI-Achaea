--[[mudlet
type: trigger
name: Immediately retry on failed teleport
hierarchy:
- mudlet-mapper
- Mudlet Mapper
- Lusternia
- Delayed bix movement.
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
- pattern: Your action disrupts your concentration and you cease reaching out to harness
  type: 2
- pattern: You cease concentrating on traveling the planar paths.
  type: 3
]]--

if mmp.autowalking then
  mmp.customwalkdelay(0)
  mmp.move()
end