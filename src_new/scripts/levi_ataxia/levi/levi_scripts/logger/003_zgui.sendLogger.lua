--[[mudlet
type: script
name: zgui.sendLogger
hierarchy:
- Levi_Ataxia
- LEVI
- Levi  Scripts
- ZulahGUI - Saonji Edit
- zGUI Redux
- Logger
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

function zgui.sendLogger(colorCode, logMessage)
  zgui.trueTime = string.cut(getTime(true, "hh:mm:ss:zzz"), 11)
	cecho("logDisplay", "<gold>"..zgui.trueTime)
	cecho("logDisplay", "<"..colorCode..">-- "..logMessage.."\n")
	deleteLine()
end