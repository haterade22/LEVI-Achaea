--[[mudlet
type: timer
name: Deathcape Timer
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- leviticus
- Levi Ataxia
- ZulahGUI - Saonji Edit
- zGUI Redux
- Death Cape
attributes:
  isActive: 'no'
  isFolder: 'no'
  isTempTimer: 'no'
  isOffsetTimer: 'no'
time: '00:00:01.000'
command: ''
packageName: ''
]]--

zgui.cape.watch = zgui.cape.watch or 0
zgui.cape.watch = zgui.cape.watch + 1
zgui.showCape()