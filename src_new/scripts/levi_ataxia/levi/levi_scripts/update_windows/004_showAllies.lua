--[[mudlet
type: script
name: showAllies
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

function zgui.showAllies()
  clearWindow("allyDisplay")
	for i=1, table.size(zgui.allies), 1 do
		cecho("allyDisplay", "<white>"..i.."- <gray>"..zgui.allies[i].."\n")
	end
end