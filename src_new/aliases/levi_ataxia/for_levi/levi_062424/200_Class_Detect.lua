--[[mudlet
type: alias
name: Class Detect
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- Ataxia-DownloadThis
- Ataxia
- Ataxia NDB
- Actions
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^csd (.+)$
command: ''
packageName: ''
]]--

local args = matches[2]:lower()
local parts = args:split(" ")
local cmd = parts[1]

if cmd == "status" or cmd == "stat" then
  classDetect.status()

elseif cmd == "on" then
  classDetect.state.enabled = true
  classDetect.echo("<green>System enabled")

elseif cmd == "off" then
  classDetect.state.enabled = false
  classDetect.echo("<red>System disabled")

elseif cmd == "reset" then
  classDetect.resetToNormal()
  classDetect.echo("Manually reset to <white>normal<plum> curingset")

elseif cmd == "set" and parts[2] and parts[3] then
  local className = parts[2]:title()
  local setName = parts[3]:lower()
  classDetect.curingsetMap[className] = setName
  classDetect.save()
  classDetect.echo("Mapped <yellow>" .. className .. "<plum> → curingset <white>" .. setName)

elseif cmd == "switch" and parts[2] then
  local className = parts[2]:title()
  classDetect.switchCuringset(className)
  classDetect.echo("Manually switched to curingset for <yellow>" .. className)

elseif cmd == "setup" then
  classDetect.setup()

elseif cmd == "save" then
  classDetect.save()
  classDetect.echo("<green>Config saved")

elseif cmd == "load" then
  classDetect.load()
  classDetect.echo("<green>Config loaded")

elseif cmd == "map" then
  cecho("\n<cyan>+==========================================+")
  cecho("\n<cyan>|     <white>CURINGSET MAP<cyan>                        |")
  cecho("\n<cyan>+==========================================+")
  local sorted = {}
  for k in pairs(classDetect.curingsetMap) do table.insert(sorted, k) end
  table.sort(sorted)
  for _, className in ipairs(sorted) do
    cecho("\n<cyan>| <yellow>" .. className .. string.rep(" ", 16 - #className) .. "<plum>→ <white>" .. classDetect.curingsetMap[className])
  end
  cecho("\n<cyan>+==========================================+\n")

else
  classDetect.echo("<white>Usage:")
  cecho("\n  <yellow>csd status<plum>         — Show current state")
  cecho("\n  <yellow>csd on<plum>/<yellow>off<plum>          — Enable/disable")
  cecho("\n  <yellow>csd reset<plum>          — Reset to normal curingset")
  cecho("\n  <yellow>csd set <class> <set><plum> — Override curingset mapping")
  cecho("\n  <yellow>csd switch <class><plum>  — Manually switch curingset")
  cecho("\n  <yellow>csd setup<plum>          — Bulk create curingsets in-game")
  cecho("\n  <yellow>csd map<plum>            — Show class→curingset mapping")
  cecho("\n  <yellow>csd save<plum>/<yellow>load<plum>      — Save/load config")
  echo("\n")
end
