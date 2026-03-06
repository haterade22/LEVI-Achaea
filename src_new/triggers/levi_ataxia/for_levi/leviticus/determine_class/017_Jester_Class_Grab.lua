--[[mudlet
type: trigger
name: Jester Class Grab
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
- pattern: ^(\w+) whispers something to a puppet of you
  type: 1
- pattern: ^(\w+) flings a .+ tarot card at you
  type: 1
- pattern: ^(\w+) throws a pie at you
  type: 1
- pattern: ^(\w+) jabs an envenomed needle into a puppet of you
  type: 1
]]--

-- Jester and Occultist share tarot — check NDB to disambiguate
local attacker = matches[2]
local knownClass = ataxiaNDB_getClass and ataxiaNDB_getClass(attacker)
if knownClass and knownClass ~= "Unknown" then
  classDetect.setAttackerClass(attacker, knownClass)
else
  classDetect.setAttackerClass(attacker, "Jester")
end
