--[[mudlet
type: trigger
name: Glass Lily Dropped
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Misc Triggers
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
- pattern: You let a clouded glass lily fall to the ground
  type: 2
]]--

-- "You let a clouded glass lily fall to the ground, its fragile form crumbling into dust upon
-- impact." (the user's log, 2026-09-30). The lily went down: its hour starts now (v4.7.367,
-- misc_scripts/024). Start of line -- the full line is ~100 characters and could wrap.
if ataxia_lilyDropped then ataxia_lilyDropped() end
