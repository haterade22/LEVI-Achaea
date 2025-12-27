--[[mudlet
type: script
name: showEnemies
hierarchy:
- Levi_Ataxia
- LEVI
- Levi  Scripts
- ZulahGUI - Saonji Edit
- zGUI Redux
- Update Windows
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

function zgui.showEnemies()
  clearWindow("enemyDisplay")
	for i=1, table.size(zgui.enemies), 1 do
		cecho("enemyDisplay", "<white>"..i.."- <gray>"..zgui.enemies[i].."\n")
	end
end