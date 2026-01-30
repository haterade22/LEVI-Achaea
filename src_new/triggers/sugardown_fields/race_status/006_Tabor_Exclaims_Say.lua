--[[mudlet
type: trigger
name: Tabor Exclaims/Say
hierarchy:
- Sugardown Fields
- Race Status
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
- pattern: ^Tabor\, the Sugardown announcer exclaims\, \".+\"$
  type: 1
- pattern: ^Tabor\, the Sugardown announcer says\, \".+\"$
  type: 1
]]--

sugardown.racetrackView()