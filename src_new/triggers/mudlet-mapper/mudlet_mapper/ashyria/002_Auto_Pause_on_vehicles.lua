--[[mudlet
type: trigger
name: Auto Pause on vehicles
hierarchy:
- mudlet-mapper
- Mudlet Mapper
- Ashyria
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
- pattern: You pay the coachman for a ride to the city of Rhojidan
  type: 2
- pattern: You pay the elven ferryman for a ride to the mainland
  type: 2
- pattern: The carriage rolls to a stop as you arrive at the southern gate of Rhojidan.
  type: 0
- pattern: 'The ferry boat slowly drifts to a stop at the western shores of Alarra. '
  type: 2
- pattern: You pay the coachman for a ride to the village of Hessa
  type: 2
- pattern: The carriage rolls to a stop as you arrive at the southern fields of Hessa.
  type: 2
- pattern: You pay the elven ferryman for a ride to Kalmyr
  type: 2
]]--

if mmp.autowalking then
  tempTimer(1, function() mmp.pause() end)
end
