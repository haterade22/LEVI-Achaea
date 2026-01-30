--[[mudlet
type: trigger
name: Not Racing
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
- pattern: Tabor, the Sugardown announcer exclaims, "Place your bets, place your bets! A new race has been scheduled!"
  type: 3
- pattern: This command will only work during a race. RACETRACK LIST is what you may be looking for.
  type: 3
]]--

sugardown.endRace()