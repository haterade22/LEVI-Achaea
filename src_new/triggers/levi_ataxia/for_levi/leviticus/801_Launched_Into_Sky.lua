--[[mudlet
type: trigger
name: Launched Into Sky
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
- pattern: A violent force suddenly takes hold of you and launches you high into the sky.
  type: 0
]]--

-- LAUNCHED INTO THE SKY (v4.7.491, user: "We need to LAND when this happens."). Dunn's piercing
-- note, kb/raw/logs/ours/2026-11-03_102828_Harkon.log rows 503, 1578, 7302. A substring, not
-- ^-anchored: our own echoes print around this line in that log. The line names "you", so only
-- our own launch matches. The landing and its guards are in misc_scripts/032_Launch_Land.lua.
if ataxia_launchedLand then ataxia_launchedLand() end
