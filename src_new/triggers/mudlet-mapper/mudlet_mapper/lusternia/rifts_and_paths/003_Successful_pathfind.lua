--[[mudlet
type: trigger
name: Successful pathfind
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
- pattern: You squat down and narrow your eyes, finally finding a mystic pathway that twists and turns in the distance. Before
    it slips away, you dash forward and rush along its winding tracks.
  type: 3
]]--

if mmp.game~= "lusternia" then return end
if validTransverse then
  mmp.clearPathfind()
  mmp.registerPathfind()
end