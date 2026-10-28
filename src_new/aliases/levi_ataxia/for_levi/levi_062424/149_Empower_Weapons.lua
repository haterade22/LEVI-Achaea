--[[mudlet
type: alias
name: Empower Weapons
hierarchy:
- Levi_Ataxia
- Classes
- Knight
- RUNIE
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^remweap(?: (list|stop))?$
command: ''
packageName: ''
]]--

-- remweap        probe every knight weapon, sketch lagul/lagua/laguz + EMPOWER the ones that
--                are not runeblades yet, then gebo/gebu on armour and shield (system paused)
-- remweap list   probe and report only
-- remweap stop   end a running job
-- The job lives in gear_system/003_Runeblade_Empower.lua.

if matches[2] == "list" then
  ataxia.runeblade.list()
elseif matches[2] == "stop" then
  ataxia.runeblade.stop()
else
  ataxia.runeblade.start()
end
