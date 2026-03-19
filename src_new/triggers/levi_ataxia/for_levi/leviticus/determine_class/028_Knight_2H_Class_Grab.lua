--[[mudlet
type: trigger
name: Knight 2H Class Grab
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
- pattern: ^(\w+) brings .+ down upon you with a brutal overhand blow\.$
  type: 1
- pattern: ^(\w+) explodes upward from a low crouch, driving .+ toward your
  type: 1
- pattern: ^(\w+) comes around with a terrible swing of .+ toward your
  type: 1
- pattern: ^(\w+) unleashes a terrible blow at your .+ with
  type: 1
]]--

-- 2H patterns are shared by all knight classes. Check NDB for specific class.
local attacker = matches[2]
local knownClass = ataxiaNDB_getClass and ataxiaNDB_getClass(attacker)
if knownClass and knownClass ~= "Unknown" then
  classDetect.setAttackerClass(attacker, knownClass)
else
  classDetect.setAttackerClass(attacker, "Runewarden")
end
classDetect.state.attackerSpec = "2H"
