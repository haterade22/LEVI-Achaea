--[[mudlet
type: trigger
name: Extracted Here
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Harvesting
- Extraction
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
- pattern: You kneel and collect chunks of earth
  type: 2
]]--

if not autoExtracting then return end
deleteFull()

bashConsoleEchom("HERB", "Extracted "..ataxiaExtraction[gmcp.Room.Info.area]..".", "SeaGreen", "a_darkgreen")

ataxiaHarvester_harvested()