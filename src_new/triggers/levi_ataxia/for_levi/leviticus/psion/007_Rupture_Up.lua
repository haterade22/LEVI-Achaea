--[[mudlet
type: trigger
name: Rupture Up
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Class Stuff
- Psion
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
- pattern: Your vision sharpens, allowing you to perceive the locations of every vein
  type: 2
- pattern: Your blows will already rupture veins and arteries.
  type: 3
]]--

-- ENACT RUPTURE took ("Your vision sharpens, ... every vein and artery that lies beneath the skin.")
-- or was already standing ("Your blows will already rupture veins and arteries."). Either way the
-- charge is up -- the Bloodletter's Fury keeper stands down (v4.7.361, basher/002).
if ataxiaBasher_psionRuptureSeen then ataxiaBasher_psionRuptureSeen(true) end
