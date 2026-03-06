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
