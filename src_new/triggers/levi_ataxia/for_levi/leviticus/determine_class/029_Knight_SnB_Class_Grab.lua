--[[mudlet
type: trigger
name: Knight SnB Class Grab
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Curing Stuff
- Priority Management
- Determine Class
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
- pattern: ^(\w+) quickly lunges to the side, bringing \w+ shield around to smash into
  type: 1
- pattern: ^(\w+) drives the edge of \w+ shield .+ into your throat
  type: 1
- pattern: ^(\w+) smashes the edge of .+ into your kneecaps
  type: 1
- pattern: ^(\w+) pivots rapidly and brings \w+ shield around to batter your head
  type: 1
]]--

-- SnB patterns are shared by all knight classes. Check NDB for specific class.
local attacker = matches[2]
local knownClass = ataxiaNDB_getClass and ataxiaNDB_getClass(attacker)
if knownClass and knownClass ~= "Unknown" then
  classDetect.setAttackerClass(attacker, knownClass)
else
  classDetect.setAttackerClass(attacker, "Runewarden")
end
