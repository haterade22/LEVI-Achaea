--[[mudlet
type: trigger
name: Already Extracted
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
- pattern: You have already extracted minerals from this location.
  type: 2
- pattern: What do you wish to extract?
  type: 3
- pattern: The environment here will not yield any minerals.
  type: 3
]]--

if not autoExtracting then return end
deleteFull()	
bashConsoleEchom("MIN", "Already extracted.", "DimGrey", "DarkSlateBlue")

ataxiaHarvester_harvested()