--[[mudlet
type: trigger
name: Waking Up
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Remove Afflictions
- Groups
- Passive/Active
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
- pattern: ^([\w'\-]+) opens \w+ eyes and yawns mightily\.$
  type: 1
- pattern: ^([\w'\-]+) wakes up with a gasp of pain\.$
  type: 1
]]--

local name = matches[2]

if isTargeted(name) then
  onClassCureV3({"sleep"})
  selectString(line, 1)
  fg("NavajoWhite")
  resetFormat()
  targetIshere = true
end
