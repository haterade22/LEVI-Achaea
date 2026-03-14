--[[mudlet
type: alias
name: Locate Enemies
hierarchy:
- Levi_Ataxia
- General
- Locate Relay
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^locate enemies$
command: ''
packageName: ''
]]--

if not ataxiaTemp.enemies or #ataxiaTemp.enemies == 0 then
  cecho("<red>[Locate] No enemies in your list.\n")
  return
end

LocateSystem.city    = "enemies"
LocateSystem.queue   = {}
LocateSystem.results = {}
LocateSystem.failed  = {}
LocateSystem.current = nil
LocateSystem.running = false
LocateSystem.retryFlag = false
LocateSystem.isEnemyScan = true
LocateSystem.whobNames   = {}
LocateSystem.whobResults = {}
LocateSystem.whobActive  = false
send("pt Locating Targets...")

for _, name in ipairs(ataxiaTemp.enemies) do
  table.insert(LocateSystem.queue, name)
end

cecho("<cyan>[Locate] Starting enemy scan for <yellow>" .. #LocateSystem.queue .. " targets<cyan>...\n")
enableTrigger("locate_relay")
LocateSystem.beginQueue()
