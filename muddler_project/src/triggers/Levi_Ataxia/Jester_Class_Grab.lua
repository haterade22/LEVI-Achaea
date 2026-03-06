-- Jester and Occultist share tarot — check NDB to disambiguate
local attacker = matches[2]
local knownClass = ataxiaNDB_getClass and ataxiaNDB_getClass(attacker)
if knownClass and knownClass ~= "Unknown" then
  classDetect.setAttackerClass(attacker, knownClass)
else
  classDetect.setAttackerClass(attacker, "Jester")
end
