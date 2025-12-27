--[[mudlet
type: trigger
name: Pause speedwalk on combat
hierarchy:
- mudlet-mapper
- Mudlet Mapper
- Ashyria
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
- pattern: You cannot move while in combat. RETREAT first.
  type: 0
]]--

if mmp.autowalking and not mmp.paused then
  mmp.pause()
  mmp.echo("Can't continue walking in combat. Use 'mmp' to continue walking after combat.")
else
  return
end