-- SnB patterns are shared by all knight classes. Check NDB for specific class.
local attacker = matches[2]
local knownClass = ataxiaNDB_getClass and ataxiaNDB_getClass(attacker)
if knownClass and knownClass ~= "Unknown" then
  classDetect.setAttackerClass(attacker, knownClass)
else
  classDetect.setAttackerClass(attacker, "Runewarden")
end
