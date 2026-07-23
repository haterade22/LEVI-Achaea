--[[mudlet
type: trigger
name: dmap Boon Screen
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
- pattern: flickers of power that may aide you
  type: 1
]]--

-- Boon-offer screen = ripple complete. Pause the sweep so you can pick a boon and wade
-- (GO / `dmap explore on` resumes). No-op unless sweeping.
if dmap and dmap.exploreOnBoonScreen then dmap.exploreOnBoonScreen() end
