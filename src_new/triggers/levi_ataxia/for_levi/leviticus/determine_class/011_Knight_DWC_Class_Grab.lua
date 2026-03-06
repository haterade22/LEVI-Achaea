--[[mudlet
type: trigger
name: Knight DWC Class Grab
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
- pattern: ^The blade of (\w+) is a blur as \w+ moves forward, slicing into your
  type: 1
- pattern: ^(\w+) carves into your .+ with a vicious strike
  type: 1
- pattern: ^Lightning-quick, (\w+) jabs your .+ with
  type: 1
- pattern: ^(\w+) lashes out at you with .+, catching you across the
  type: 1
- pattern: ^(\w+) whips .+ through the air in front of you, to no effect
  type: 1
]]--

-- DWC slash patterns are shared by all knight classes.
-- Check NDB first for specific class; fall back to generic lookup.
local attacker = matches[2]
local knownClass = ataxiaNDB_getClass and ataxiaNDB_getClass(attacker)
if knownClass and knownClass ~= "Unknown" then
  classDetect.setAttackerClass(attacker, knownClass)
else
  -- Generic knight — API lookup will refine later
  classDetect.setAttackerClass(attacker, "Runewarden")
end
