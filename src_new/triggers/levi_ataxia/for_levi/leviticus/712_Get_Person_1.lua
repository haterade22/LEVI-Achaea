--[[mudlet
type: trigger
name: Get Person
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Ataxia NDB
- Who Grouping
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
- pattern: ^(\w+)$
  type: 1
- pattern: ^(\w+) \s+ \((.+)\)$
  type: 1
]]--

if not matches[3] then
  whogroups.unknown = whogroups.unknown or {}
  table.insert(whogroups.unknown, matches[2])
  table.sort(whogroups.unknown)
else
  whogroups[matches[3]] = whogroups[matches[3]] or {}
  table.insert(whogroups[matches[3]], matches[2])
  table.sort(whogroups[matches[3]])  
end

deleteLine()