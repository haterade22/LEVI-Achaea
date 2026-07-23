--[[mudlet
type: trigger
name: dmap Ice Slip
hierarchy:
- Dementia_Mapper
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
- pattern: ^You slip and fall on the ice
  type: 1
]]--

-- Icy room: the move failed (you fell prone) but the exit is fine -- let the explorer re-send
-- the move rather than condemning the exit. No-op unless a sweep is running.
if dmap and dmap.exploreIceSlip then dmap.exploreIceSlip() end
