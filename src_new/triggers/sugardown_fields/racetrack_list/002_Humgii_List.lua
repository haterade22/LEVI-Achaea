--[[mudlet
type: trigger
name: Humgii List
hierarchy:
- Sugardown Fields
- Racetrack List
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
- pattern: ^(.+?)\s+\d+\s+(\d+)\s+(.+?)\s+\d+\s+(\d+)\s+[\d.]+:[\d.]+\s+\((\d+)\s*(?:c|cr)\)?\s+[\d.]+:[\d.]+\s+\((\d+)\s*(?:c|cr)\)?\s+[\d.]+:[\d.]+\s+\((\d+)\s*(?:c|cr)\)?
  type: 1
]]--

table.insert(humgiiList, {
  name     = matches[2],
  points   = tonumber(matches[3]),
  jockey   = matches[4],
  jockeyPts= tonumber(matches[5]),
  winCr    = tonumber(matches[6]),
  placeCr  = tonumber(matches[7]),
  showCr   = tonumber(matches[8]),
})


deleteLine()