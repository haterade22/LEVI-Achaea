--[[mudlet
type: timer
name: Clear Bashing Console
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- leviticus
- Levi Ataxia
- MY TIMERS
attributes:
  isActive: 'no'
  isFolder: 'no'
  isTempTimer: 'no'
  isOffsetTimer: 'no'
time: '00:01:10.000'
command: ''
packageName: ''
]]--

if zgui then
  zgui.bwindow.console:clear()
else
  ataxiagui.bashConsole:clear()
end