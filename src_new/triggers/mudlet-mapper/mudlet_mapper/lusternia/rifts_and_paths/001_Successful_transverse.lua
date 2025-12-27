--[[mudlet
type: trigger
name: Successful transverse
hierarchy:
- mudlet-mapper
- Mudlet Mapper
- Lusternia
- Rifts and Paths
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
- pattern: ^You (place your hands on|reach out to) .+ and find the link to .+\. Pulsating energy flares throughout your field
    of vision, and you find yourself tumbling through the aether pathways\.$
  type: 1
]]--

if mmp.game~= "lusternia" then return end
if validTransverse then
  mmp.registerTransverseExit()
end